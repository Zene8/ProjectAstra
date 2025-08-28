from fastapi import APIRouter, Depends, HTTPException, Request, status
from fastapi.responses import RedirectResponse, HTMLResponse
from urllib.parse import quote_plus
import httpx
import os
from typing import Annotated
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from database import get_session
from models import User
from main import get_current_user_id # Import from main to reuse dependency

router = APIRouter()

# --- Configuration (Load from environment variables) ---
# IMPORTANT: Replace these with your actual values from Azure AD App Registration
# It's recommended to use a .env file and a library like python-dotenv for production
TENANT_ID = os.getenv("OUTLOOK_TENANT_ID")
CLIENT_ID = os.getenv("OUTLOOK_CLIENT_ID")
CLIENT_SECRET = os.getenv("OUTLOOK_CLIENT_SECRET")
REDIRECT_URI = os.getenv("OUTLOOK_REDIRECT_URI", "http://localhost:5000/api/outlook/auth/callback") # Default to backend's port

AUTHORITY = f"https://login.microsoftonline.com/{TENANT_ID}"
GRAPH_API_ENDPOINT = "https://graph.microsoft.com/v1.0/"
# Scopes required for sending mail and getting a refresh token
SCOPE = ["Mail.Send", "User.Read", "offline_access"]

@router.get("/outlook/auth/login")
async def outlook_login(user_id: Annotated[int, Depends(get_current_user_id)]):
    """
    Initiates the OAuth2 Authorization Code Flow for Outlook by redirecting to Microsoft's login page.
    """
    if not all([TENANT_ID, CLIENT_ID, CLIENT_SECRET]):
        raise HTTPException(status_code=500, detail="Outlook API credentials not configured.")

    auth_url = (
        f"{AUTHORITY}/oauth2/v2.0/authorize?"
        f"client_id={CLIENT_ID}&"
        f"response_type=code&"
        f"redirect_uri={quote_plus(REDIRECT_URI)}&"
        f"response_mode=query&"
        f"scope={quote_plus(' '.join(SCOPE))}&"
        f"state={user_id}" # Use user_id as state for simplicity, in production use a proper CSRF token
    )
    return RedirectResponse(auth_url)

@router.get("/outlook/auth/callback")
async def outlook_auth_callback(
    request: Request,
    code: str = None,
    state: str = None, # This should be the user_id passed in the login
    error: str = None,
    error_description: str = None,
    session: AsyncSession = Depends(get_session)
):
    """
    Callback endpoint for Microsoft's OAuth2 redirect.
    Exchanges the authorization code for an access token and stores it for the user.
    """
    if error:
        raise HTTPException(status_code=400, detail=f"OAuth error: {error_description}")

    if not state:
        raise HTTPException(status_code=400, detail="State parameter missing. Possible CSRF attack or invalid redirect.")
    
    user_id = int(state) # Convert state back to user_id

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

    # Store tokens securely in the database for the user
    user = (await session.execute(select(User).where(User.id == user_id))).scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found.")
    
    user.outlook_access_token = access_token
    user.outlook_refresh_token = refresh_token
    session.add(user)
    await session.commit()
    await session.refresh(user)

    return HTMLResponse("<h1>Outlook Authentication Successful!</h1><p>You can close this window.</p>")

@router.get("/outlook/inbox")
async def get_outlook_emails(user_id: Annotated[int, Depends(get_current_user_id)], session: AsyncSession = Depends(get_session)):
    """
    Fetches emails from the Outlook inbox using the Microsoft Graph API.
    """
    user = (await session.execute(select(User).where(User.id == user_id))).scalars().first()
    if not user or not user.outlook_access_token:
        raise HTTPException(status_code=401, detail="Outlook not authenticated for this user.")

    # TODO: Implement token refresh logic if access token is expired
    access_token = user.outlook_access_token

    messages_url = f"{GRAPH_API_ENDPOINT}me/mailFolders/inbox/messages?$top=10" # Get top 10 messages
    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json",
    }

    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(messages_url, headers=headers)
            response.raise_for_status()
            messages_data = response.json().get("value", [])

            email_list = []
            for msg in messages_data:
                email_list.append({
                    "sender": msg.get("sender", {}).get("emailAddress", {}).get("address", "Unknown Sender"),
                    "subject": msg.get("subject", "No Subject"),
                    "body": msg.get("bodyPreview", "No Body Preview") # bodyPreview is a snippet
                })
            return email_list
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=f"Failed to fetch emails from Outlook: {e.response.text}")
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {str(e)}")

@router.post("/outlook/send_email")
async def send_outlook_email(
    recipient_email: str,
    subject: str,
    body: str,
    user_id: Annotated[int, Depends(get_current_user_id)],
    session: AsyncSession = Depends(get_session)
):
    """
    Sends an email using the Microsoft Graph API for the authenticated user.
    """
    user = (await session.execute(select(User).where(User.id == user_id))).scalars().first()
    if not user or not user.outlook_access_token:
        raise HTTPException(status_code=401, detail="Outlook not authenticated for this user.")

    # TODO: Implement token refresh logic if access token is expired
    access_token = user.outlook_access_token

    send_mail_url = f"{GRAPH_API_ENDPOINT}me/sendMail"
    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json",
    }

    email_payload = {
        "message": {
            "subject": subject,
            "body": {
                "contentType": "Text",
                "content": body
            },
            "toRecipients": [
                {
                    "emailAddress": {
                        "address": recipient_email
                    }
                }
            ]
        },
        "saveToSentItems": "true"
    }

    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(send_mail_url, headers=headers, json=email_payload)
            response.raise_for_status()
            return {"message": "Email sent successfully!", "status_code": response.status_code}
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=f"Failed to send email: {e.response.text}")
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {str(e)}")
