
from fastapi import APIRouter, Depends, HTTPException, Request
from google.auth.transport.requests import Request as GoogleAuthRequest
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import Flow
from googleapiclient.discovery import build
from sqlmodel import Session, select
import base64
from email.mime.text import MIMEText

from database import get_session
from models import User
from .auth import get_current_user
from . import email_crud, email_schemas

router = APIRouter()

# Google Gmail API scopes
SCOPES = ['https://www.googleapis.com/auth/gmail.compose', 'https://www.googleapis.com/auth/gmail.readonly']

@router.get("/google_gmail_auth")
async def google_gmail_auth(request: Request):
    flow = Flow.from_client_secrets_file(
        'client_secret.json', scopes=SCOPES, redirect_uri=str(request.url_for('google_gmail_auth_callback'))
    )
    authorization_url, state = flow.authorization_url(access_type='offline', include_granted_scopes='true')
    return {"authorization_url": authorization_url, "state": state}

@router.get("/google_gmail_auth_callback")
async def google_gmail_auth_callback(request: Request, state: str, code: str, db: Session = Depends(get_session), user: User = Depends(get_current_user)):
    flow = Flow.from_client_secrets_file(
        'client_secret.json', scopes=SCOPES, state=state, redirect_uri=str(request.url_for('google_gmail_auth_callback'))
    )
    flow.fetch_token(code=code)
    credentials = flow.credentials

    user.google_credentials = credentials.to_json()
    db.add(user)
    db.commit()
    db.refresh(user)

    return {"message": "Google Gmail connected successfully!"}

@router.post("/users/{user_id}/emails/", response_model=email_schemas.Email)
def create_email_for_user(
    user_id: int, email: email_schemas.EmailCreate, db: Session = Depends(get_session)
):
    return email_crud.create_email(db=db, email=email, user_id=user_id)

@router.get("/users/{user_id}/emails/", response_model=list[email_schemas.Email])
def read_emails(
    user_id: int, skip: int = 0, limit: int = 100, db: Session = Depends(get_session)
):
    emails = email_crud.get_emails(db, user_id=user_id, skip=skip, limit=limit)
    return emails

@router.put("/users/{user_id}/emails/{email_id}", response_model=email_schemas.Email)
def update_email_for_user(
    user_id: int, email_id: int, email: email_schemas.EmailCreate, db: Session = Depends(get_session)
):
    db_email = email_crud.update_email(db=db, email_id=email_id, email=email)
    if db_email is None:
        raise HTTPException(status_code=404, detail="Email not found")
    return db_email

@router.delete("/users/{user_id}/emails/{email_id}")
def delete_email_for_user(
    user_id: int, email_id: int, db: Session = Depends(get_session)
):
    result = email_crud.delete_email(db=db, email_id=email_id)
    if result is None:
        raise HTTPException(status_code=404, detail="Email not found")
    return result

@router.get("/email/gmail/inbox") # Changed path
async def get_google_emails(db: Session = Depends(get_session), user: User = Depends(get_current_user)):
    if not user.google_credentials:
        raise HTTPException(status_code=401, detail="Google account not linked")

    credentials = Credentials.from_authorized_user_info(user.google_credentials)
    
    if credentials.expired and credentials.refresh_token:
        credentials.refresh(GoogleAuthRequest())

    service = build('gmail', 'v1', credentials=credentials)
    
    # Call the Gmail API
    results = service.users().messages().list(userId='me', labelIds=['INBOX']).execute()
    messages = results.get('messages', [])

    email_list = []
    for message_info in messages[:10]: # Get first 10 emails
        msg = service.users().messages().get(userId='me', id=message_info['id']).execute()
        
        # Extract sender, subject, and body for frontend Email model
        sender = next((h['value'] for h in msg['payload']['headers'] if h['name'] == 'From'), 'Unknown Sender')
        subject = next((h['value'] for h in msg['payload']['headers'] if h['name'] == 'Subject'), 'No Subject')
        
        # Decode email body (handling different parts and encodings)
        body_data = ''
        if 'parts' in msg['payload']:
            for part in msg['payload']['parts']:
                if part['mimeType'] == 'text/plain' and 'body' in part and 'data' in part['body']:
                    body_data = base64.urlsafe_b64decode(part['body']['data']).decode('utf-8')
                    break
                elif part['mimeType'] == 'text/html' and 'body' in part and 'data' in part['body']:
                    # For HTML, you might want to strip HTML tags or just use it as is
                    body_data = base64.urlsafe_b64decode(part['body']['data']).decode('utf-8')
                    break
        elif 'body' in msg['payload'] and 'data' in msg['payload']['body']:
            body_data = base64.urlsafe_b64decode(msg['payload']['body']['data']).decode('utf-8')

        email_list.append({
            "sender": sender,
            "subject": subject,
            "body": body_data
        })

    return email_list # Return list directly

@router.post("/email/gmail/send") # Changed path
async def send_google_email(email: email_schemas.GoogleEmail, db: Session = Depends(get_session), user: User = Depends(get_current_user)):
    if not user.google_credentials:
        raise HTTPException(status_code=401, detail="Google account not linked")

    credentials = Credentials.from_authorized_user_info(user.google_credentials)

    if credentials.expired and credentials.refresh_token:
        credentials.refresh(GoogleAuthRequest())

    service = build('gmail', 'v1', credentials=credentials)

    message = MIMEText(email.message)
    message['to'] = ', '.join(email.to)
    message['subject'] = email.subject
    raw_message = base64.urlsafe_b64encode(message.as_bytes()).decode()

    body = {'raw': raw_message}
    
    try:
        message = (service.users().messages().send(userId="me", body=body).execute())
        return {"message": "Email sent successfully!", "message_id": message['id']}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
