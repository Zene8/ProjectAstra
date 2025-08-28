from fastapi import APIRouter, Depends, HTTPException, Request, status, UploadFile, File
from fastapi.responses import RedirectResponse, HTMLResponse, StreamingResponse
from urllib.parse import quote_plus
import httpx
import os
from typing import Annotated, List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select
from pydantic import BaseModel
import io

from database import get_session
from models import User
from main import get_current_user_id # Import from main to reuse dependency

router = APIRouter()

# --- Configuration (Load from environment variables) ---
TENANT_ID = os.getenv("ONEDRIVE_TENANT_ID")
CLIENT_ID = os.getenv("ONEDRIVE_CLIENT_ID")
CLIENT_SECRET = os.getenv("ONEDRIVE_CLIENT_SECRET")
REDIRECT_URI = os.getenv("ONEDRIVE_REDIRECT_URI", "http://localhost:5000/api/onedrive/auth/callback")

AUTHORITY = f"https://login.microsoftonline.com/{TENANT_ID}"
GRAPH_API_ENDPOINT = "https://graph.microsoft.com/v1.0/"
# Scopes required for OneDrive
SCOPE = ["Files.ReadWrite.All", "offline_access", "User.Read"] # Files.ReadWrite.All for full access

@router.get("/onedrive/auth/login")
async def onedrive_login(user_id: Annotated[int, Depends(get_current_user_id)]):
    """
    Initiates the OAuth2 Authorization Code Flow for OneDrive.
    """
    if not all([TENANT_ID, CLIENT_ID, CLIENT_SECRET]):
        raise HTTPException(status_code=500, detail="OneDrive API credentials not configured.")

    auth_url = (
        f"{AUTHORITY}/oauth2/v2.0/authorize?"
        f"client_id={CLIENT_ID}&"
        f"response_type=code&"
        f"redirect_uri={quote_plus(REDIRECT_URI)}&"
        f"response_mode=query&"
        f"scope={quote_plus(' '.join(SCOPE))}&"
        f"state={user_id}"
    )
    return RedirectResponse(auth_url)

@router.get("/onedrive/auth/callback")
async def onedrive_auth_callback(
    request: Request,
    code: str = None,
    state: str = None,
    error: str = None,
    error_description: str = None,
    session: AsyncSession = Depends(get_session)
):
    """
    Callback endpoint for OneDrive OAuth2 redirect.
    Exchanges the authorization code for an access token and stores it for the user.
    """
    if error:
        raise HTTPException(status_code=400, detail=f"OAuth error: {error_description}")

    if not state:
        raise HTTPException(status_code=400, detail="State parameter missing. Possible CSRF attack or invalid redirect.")
    
    user_id = int(state)

    token_url = f"{AUTHORITY}/oauth2/v2.0/token"
    token_data = {
        "client_id": CLIENT_ID,
        "scope": " ".join(SCOPE),
        "code": code,
        "redirect_uri": REDIRECT_URI,
        "grant_type": "authorization_code",
        "client_secret": CLIENT_SECRET,
    }

    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(token_url, data=token_data)
            response.raise_for_status()
            tokens = response.json()
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=f"Failed to get tokens: {e.response.text}")
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"An unexpected error occurred during token exchange: {str(e)}")

    access_token = tokens.get("access_token")
    refresh_token = tokens.get("refresh_token")

    if not access_token:
        raise HTTPException(status_code=500, detail="Failed to retrieve access token from response.")

    user = (await session.execute(select(User).where(User.id == user_id))).scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found.")
    
    user.onedrive_access_token = access_token
    user.onedrive_refresh_token = refresh_token
    session.add(user)
    await session.commit()
    await session.refresh(user)

    return HTMLResponse("<h1>OneDrive Authentication Successful!</h1><p>You can close this window.</p>")

async def get_onedrive_access_token(user_id: int, session: AsyncSession) -> str:
    user = (await session.execute(select(User).where(User.id == user_id))).scalars().first()
    if not user or not user.onedrive_access_token:
        raise HTTPException(status_code=401, detail="OneDrive not authenticated for this user.")
    
    # TODO: Implement token refresh logic if access token is expired
    return user.onedrive_access_token

@router.get("/onedrive/files")
async def list_onedrive_files(
    user_id: Annotated[int, Depends(get_current_user_id)],
    session: AsyncSession = Depends(get_session),
    path: str = "" # Path relative to root, e.g., "Documents/MyFolder"
):
    """
    Lists files and folders in a specified OneDrive path.
    """
    access_token = await get_onedrive_access_token(user_id, session)
    
    if path:
        list_url = f"{GRAPH_API_ENDPOINT}me/drive/root:/{path}:/children"
    else:
        list_url = f"{GRAPH_API_ENDPOINT}me/drive/root/children"

    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json",
    }

    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(list_url, headers=headers)
            response.raise_for_status()
            return response.json().get("value", [])
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=f"Failed to list OneDrive files: {e.response.text}")
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {str(e)}")

@router.post("/onedrive/upload")
async def upload_onedrive_file(
    user_id: Annotated[int, Depends(get_current_user_id)],
    session: AsyncSession = Depends(get_session),
    file: UploadFile = File(...),
    path: str = "" # Path relative to root where file will be uploaded
):
    """
    Uploads a file to a specified OneDrive path.
    """
    access_token = await get_onedrive_access_token(user_id, session)
    
    upload_url = f"{GRAPH_API_ENDPOINT}me/drive/root:/{path}/{file.filename}:/content"
    
    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": file.content_type,
    }

    async with httpx.AsyncClient() as client:
        try:
            content = await file.read()
            response = await client.put(upload_url, headers=headers, content=content)
            response.raise_for_status()
            return response.json()
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=f"Failed to upload file to OneDrive: {e.response.text}")
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {str(e)}")

@router.get("/onedrive/download/{item_id}")
async def download_onedrive_file(
    item_id: str,
    user_id: Annotated[int, Depends(get_current_user_id)],
    session: AsyncSession = Depends(get_session)
):
    """
    Downloads a file from OneDrive by item ID.
    """
    access_token = await get_onedrive_access_token(user_id, session)
    
    download_url = f"{GRAPH_API_ENDPOINT}me/drive/items/{item_id}/content"
    
    headers = {
        "Authorization": f"Bearer {access_token}",
    }

    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(download_url, headers=headers)
            response.raise_for_status()
            
            # Stream the content back to the client
            return StreamingResponse(io.BytesIO(response.content), media_type=response.headers['Content-Type'])
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=f"Failed to download file from OneDrive: {e.response.text}")
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {str(e)}")

@router.delete("/onedrive/delete/{item_id}")
async def delete_onedrive_item(
    item_id: str,
    user_id: Annotated[int, Depends(get_current_user_id)],
    session: AsyncSession = Depends(get_session)
):
    """
    Deletes a file or folder from OneDrive by item ID.
    """
    access_token = await get_onedrive_access_token(user_id, session)
    
    delete_url = f"{GRAPH_API_ENDPOINT}me/drive/items/{item_id}"
    
    headers = {
        "Authorization": f"Bearer {access_token}",
    }

    async with httpx.AsyncClient() as client:
        try:
            response = await client.delete(delete_url, headers=headers)
            response.raise_for_status()
            return {"message": "Item deleted successfully!"}
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=f"Failed to delete item from OneDrive: {e.response.text}")
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {str(e)}")
