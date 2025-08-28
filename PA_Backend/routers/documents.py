from fastapi import APIRouter, Depends, HTTPException, Request, status, UploadFile, File
from fastapi.responses import RedirectResponse, HTMLResponse, StreamingResponse
from sqlmodel import Session, select
from google.auth.transport.requests import Request as GoogleAuthRequest
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
import base64
import io
import os
from typing import Annotated, Optional
import json # Import json for parsing file metadata

from database import get_session
from . import documents_crud, documents_schemas
from .auth import get_current_user
from models import User
from main import get_current_user_id # Import from main to reuse dependency

router = APIRouter()

# Google Drive API scopes
SCOPES = ['https://www.googleapis.com/auth/drive.file', 'https://www.googleapis.com/auth/drive.readonly'] # drive.file for files created/opened by the app

@router.get("/documents/google/auth")
async def google_drive_auth(request: Request):
    flow = Flow.from_client_secrets_file(
        'client_secret.json', scopes=SCOPES, redirect_uri=str(request.url_for('google_drive_auth_callback'))
    )
    authorization_url, state = flow.authorization_url(access_type='offline', include_granted_scopes='true')
    return {"authorization_url": authorization_url, "state": state}

@router.get("/documents/google/auth_callback")
async def google_drive_auth_callback(request: Request, state: str, code: str, db: Session = Depends(get_session), user: User = Depends(get_current_user)):
    flow = Flow.from_client_secrets_file(
        'client_secret.json', scopes=SCOPES, state=state, redirect_uri=str(request.url_for('google_drive_auth_callback'))
    )
    flow.fetch_token(code=code)
    credentials = flow.credentials

    user.google_credentials = credentials.to_json() # Assuming google_credentials stores all Google tokens
    db.add(user)
    db.commit()
    db.refresh(user)

    return HTMLResponse("<h1>Google Drive Connected!</h1><p>You can close this window.</p>")

async def get_google_drive_service(user_id: int, session: Session) -> build:
    user = session.query(User).filter(User.id == user_id).first()
    if not user or not user.google_credentials:
        raise HTTPException(status_code=401, detail="Google Drive not authenticated for this user.")

    credentials = Credentials.from_authorized_user_info(user.google_credentials)
    
    if credentials.expired and credentials.refresh_token:
        credentials.refresh(GoogleAuthRequest())
        user.google_credentials = credentials.to_json()
        session.add(user)
        session.commit()
        session.refresh(user)

    return build('drive', 'v3', credentials=credentials)

@router.get("/documents/google/files")
async def list_google_drive_files(
    user_id: Annotated[int, Depends(get_current_user_id)],
    db: Session = Depends(get_session),
    folder_id: Optional[str] = None
):
    """
    Lists files and folders in Google Drive.
    """
    service = await get_google_drive_service(user_id, db)
    
    query = "'root' in parents"
    if folder_id:
        query = f"'{folder_id}' in parents"

    results = service.files().list(
        q=query,
        pageSize=10,
        fields="nextPageToken, files(id, name, mimeType, modifiedTime)"
    ).execute()
    items = results.get('files', [])

    file_list = []
    for item in items:
        file_list.append({
            "id": item['id'],
            "title": item['name'],
            "mimeType": item['mimeType'],
            "lastModified": item['modifiedTime']
        })
    return file_list

@router.get("/documents/google/download/{document_id}")
async def download_google_drive_file(
    document_id: str,
    user_id: Annotated[int, Depends(get_current_user_id)],
    db: Session = Depends(get_session)
):
    """
    Downloads content of a Google Drive file.
    """
    service = await get_google_drive_service(user_id, db)
    
    # For Google Docs, Sheets, Slides, etc., use export_media
    # For other files, use get_media
    file_metadata = service.files().get(fileId=document_id, fields="mimeType, name").execute()
    mime_type = file_metadata.get('mimeType')
    file_name = file_metadata.get('name')

    if mime_type == 'application/vnd.google-apps.document':
        request = service.files().export_media(fileId=document_id, mimeType='text/plain')
    elif mime_type == 'application/vnd.google-apps.spreadsheet':
        request = service.files().export_media(fileId=document_id, mimeType='text/csv')
    elif mime_type == 'application/vnd.google-apps.presentation':
        request = service.files().export_media(fileId=document_id, mimeType='text/plain')
    else:
        request = service.files().get_media(fileId=document_id)

    fh = io.BytesIO()
    downloader = httpx.Client() # Use httpx for streaming download
    response = downloader.send(httpx.Request("GET", request.uri, headers=request.headers), stream=True)
    for chunk in response.iter_bytes():
        fh.write(chunk)
    fh.seek(0)
    
    return StreamingResponse(fh, media_type=mime_type, headers={"Content-Disposition": f"attachment; filename=\"{file_name}\""})

@router.post("/documents/google/upload")
async def upload_google_drive_file(
    user_id: Annotated[int, Depends(get_current_user_id)],
    db: Session = Depends(get_session),
    file: UploadFile = File(...),
    folder_id: Optional[str] = None
):
    """
    Uploads a file to Google Drive.
    """
    service = await get_google_drive_service(user_id, db)
    
    file_metadata = {'name': file.filename}
    if folder_id:
        file_metadata['parents'] = [folder_id]

    media = httpx.Client().send(httpx.Request("POST", "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart",
                                              headers={"Authorization": f"Bearer {service.credentials.token}"},
                                              files={'metadata': (None, json.dumps(file_metadata), 'application/json'),
                                                     'file': (file.filename, await file.read(), file.content_type)}))
    media.raise_for_status()
    return media.json()

@router.delete("/documents/google/delete/{document_id}")
async def delete_google_drive_file(
    document_id: str,
    user_id: Annotated[int, Depends(get_current_user_id)],
    db: Session = Depends(get_session)
):
    """
    Deletes a file from Google Drive.
    """
    service = await get_google_drive_service(user_id, db)
    
    service.files().delete(fileId=document_id).execute()
    return {"message": "File deleted successfully!"}

# --- Local Document CRUD (Existing) ---
@router.post("/users/{user_id}/documents/", response_model=documents_schemas.Document)
def create_document_for_user(
    user_id: int, document: documents_schemas.DocumentCreate, db: Session = Depends(get_session)
):
    return documents_crud.create_document(db=db, document=document, user_id=user_id)

@router.get("/users/{user_id}/documents/", response_model=list[documents_schemas.Document])
def read_documents(
    user_id: int, skip: int = 0, limit: int = 100, db: Session = Depends(get_session)
):
    documents = documents_crud.get_documents(db, user_id=user_id, skip=skip, limit=limit)
    return documents

@router.put("/users/{user_id}/documents/{document_id}", response_model=documents_schemas.Document)
def update_document_for_user(
    user_id: int, document_id: int, document: documents_schemas.DocumentCreate, db: Session = Depends(get_session)
):
    db_document = documents_crud.update_document(db=db, document_id=document_id, document=document)
    if db_document is None:
        raise HTTPException(status_code=404, detail="Document not found")
    return db_document

@router.delete("/users/{user_id}/documents/{document_id}")
def delete_document_for_user(
    user_id: int, document_id: int, db: Session = Depends(get_session)
):
    result = documents_crud.delete_document(db=db, document_id=document_id)
    if result is None:
        raise HTTPException(status_code=404, detail="Document not found")
    return result
