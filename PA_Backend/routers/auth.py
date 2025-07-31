from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import RedirectResponse
from google_auth_oauthlib.flow import Flow
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from sqlmodel import Session, select

from database import get_session
from models import User

router = APIRouter()

# This should be configured securely, e.g., via environment variables
CLIENT_SECRETS_FILE = 'client_secret.json'
SCOPES = [
    'https://www.googleapis.com/auth/gmail.readonly',
    'https://www.googleapis.com/auth/calendar.readonly',
    'https://www.googleapis.com/auth/tasks.readonly'
]
REDIRECT_URI = 'http://localhost:8000/api/auth/google/callback'

@router.get("/auth/google/login")
async def login_google():
    flow = Flow.from_client_secrets_file(
        CLIENT_SECRETS_FILE, scopes=SCOPES, redirect_uri=REDIRECT_URI
    )
    authorization_url, state = flow.authorization_url(
        access_type='offline', include_granted_scopes='true'
    )
    return RedirectResponse(authorization_url)

@router.get("/auth/google/callback")
async def auth_google_callback(code: str, session: Session = Depends(get_session)):
    flow = Flow.from_client_secrets_file(
        CLIENT_SECRETS_FILE, scopes=SCOPES, redirect_uri=REDIRECT_URI
    )
    flow.fetch_token(code=code)
    credentials = flow.credentials

    # Get user info from Google
    service = build('oauth2', 'v2', credentials=credentials)
    user_info = service.userinfo().get().execute()
    
    email = user_info.get('email')
    if not email:
        raise HTTPException(status_code=400, detail="Email not found in Google profile")

    # Check if user exists, or create a new one
    user = (await session.execute(select(User).where(User.email == email))).scalars().first()
    if not user:
        user = User(email=email)
    
    # Save credentials
    user.google_credentials = credentials.to_json()
    session.add(user)
    await session.commit()
    await session.refresh(user)

    return {"message": "Authentication successful"}
