from fastapi import APIRouter, Depends, HTTPException
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from sqlmodel import Session, select

from database import get_session
from models import User

router = APIRouter()

def get_current_user(session: Session = Depends(get_session)):
    # This is a placeholder for a real user session management system.
    # In a real app, you would get the user ID from a session cookie or token.
    user = session.exec(select(User)).first()
    if not user:
        raise HTTPException(status_code=401, detail="Not authenticated")
    return user

@router.get("/email")
async def get_emails(user: User = Depends(get_current_user)):
    if not user.google_credentials:
        raise HTTPException(status_code=401, detail="Google account not linked")

    credentials = Credentials.from_authorized_user_info(user.google_credentials)
    
    if credentials.expired and credentials.refresh_token:
        credentials.refresh(Request())

    service = build('gmail', 'v1', credentials=credentials)
    
    # Call the Gmail API
    results = service.users().messages().list(userId='me', labelIds=['INBOX']).execute()
    messages = results.get('messages', [])

    email_list = []
    for message_info in messages[:10]: # Get first 10 emails
        msg = service.users().messages().get(userId='me', id=message_info['id']).execute()
        email_data = {
            "id": msg['id'],
            "snippet": msg['snippet'],
            "headers": {h['name']: h['value'] for h in msg['payload']['headers']}
        }
        email_list.append(email_data)

    return {"emails": email_list}