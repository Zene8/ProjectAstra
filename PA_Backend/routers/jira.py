from fastapi import APIRouter, Depends, HTTPException, Request, status
from fastapi.responses import RedirectResponse, HTMLResponse
from urllib.parse import quote_plus
import httpx
import os
from typing import Annotated, List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select
from pydantic import BaseModel

from database import get_session
from models import User
from main import get_current_user_id # Import from main to reuse dependency

router = APIRouter()

# --- Configuration (Load from environment variables) ---
# These should be obtained from your Atlassian Developer Console OAuth 2.0 app
CLIENT_ID = os.getenv("JIRA_CLIENT_ID")
CLIENT_SECRET = os.getenv("JIRA_CLIENT_SECRET")
REDIRECT_URI = os.getenv("JIRA_REDIRECT_URI", "http://localhost:5000/api/jira/auth/callback")
# Your Jira Cloud site URL, e.g., "https://your-domain.atlassian.net"
JIRA_SITE_URL = os.getenv("JIRA_SITE_URL") 

AUTHORIZATION_URL = "https://auth.atlassian.com/authorize"
TOKEN_URL = "https://auth.atlassian.com/oauth/token"
# Scopes required for Jira
SCOPE = ["read:jira-user", "read:jira-work", "write:jira-work", "offline_access"]

class JiraIssueCreate(BaseModel):
    project_key: str
    summary: str
    description: Optional[str] = None
    issue_type: str = "Task" # Default issue type

class JiraIssueUpdate(BaseModel):
    summary: Optional[str] = None
    description: Optional[str] = None
    status: Optional[str] = None # e.g., "Done", "In Progress"

@router.get("/jira/auth/login")
async def jira_login(user_id: Annotated[int, Depends(get_current_user_id)]):
    """
    Initiates the OAuth2 Authorization Code Flow for Jira.
    """
    if not all([CLIENT_ID, CLIENT_SECRET, JIRA_SITE_URL]):
        raise HTTPException(status_code=500, detail="Jira API credentials or site URL not configured.")

    auth_url = (
        f"{AUTHORIZATION_URL}?"
        f"client_id={CLIENT_ID}&"
        f"response_type=code&"
        f"redirect_uri={quote_plus(REDIRECT_URI)}&"
        f"scope={quote_plus(' '.join(SCOPE))}&"
        f"state={user_id}"
    )
    return RedirectResponse(auth_url)

@router.get("/jira/auth/callback")
async def jira_auth_callback(
    request: Request,
    code: str = None,
    state: str = None,
    error: str = None,
    error_description: str = None,
    session: AsyncSession = Depends(get_session)
):
    """
    Callback endpoint for Jira OAuth2 redirect.
    Exchanges the authorization code for an access token and stores it for the user.
    """
    if error:
        raise HTTPException(status_code=400, detail=f"OAuth error: {error_description}")

    if not state:
        raise HTTPException(status_code=400, detail="State parameter missing. Possible CSRF attack or invalid redirect.")
    
    user_id = int(state)

    token_data = {
        "grant_type": "authorization_code",
        "client_id": CLIENT_ID,
        "client_secret": CLIENT_SECRET,
        "code": code,
        "redirect_uri": REDIRECT_URI,
    }

    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(TOKEN_URL, data=token_data)
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
    
    user.jira_access_token = access_token
    user.jira_refresh_token = refresh_token
    session.add(user)
    await session.commit()
    await session.refresh(user)

    return HTMLResponse("<h1>Jira Authentication Successful!</h1><p>You can close this window.</p>")

async def get_jira_access_token(user_id: int, session: AsyncSession) -> str:
    user = (await session.execute(select(User).where(User.id == user_id))).scalars().first()
    if not user or not user.jira_access_token:
        raise HTTPException(status_code=401, detail="Jira not authenticated for this user.")
    
    # TODO: Implement token refresh logic if access token is expired
    return user.jira_access_token

@router.get("/jira/projects")
async def get_jira_projects(access_token: Annotated[str, Depends(get_jira_access_token)]):
    """
    Fetches Jira projects.
    """
    projects_url = f"{JIRA_SITE_URL}/rest/api/3/project/search"
    headers = {
        "Authorization": f"Bearer {access_token}",
        "Accept": "application/json",
    }
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(projects_url, headers=headers)
            response.raise_for_status()
            return response.json().get("values", [])
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=f"Failed to fetch Jira projects: {e.response.text}")
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {str(e)}")

@router.get("/jira/issues")
async def get_jira_issues(
    access_token: Annotated[str, Depends(get_jira_access_token)],
    project_key: Optional[str] = None,
    jql: Optional[str] = None # Jira Query Language
):
    """
    Fetches Jira issues.
    """
    search_url = f"{JIRA_SITE_URL}/rest/api/3/search"
    headers = {
        "Authorization": f"Bearer {access_token}",
        "Accept": "application/json",
    }
    params = {}
    if project_key:
        params["jql"] = f"project = \"{project_key}\""
    if jql:
        params["jql"] = jql # Overrides project_key if jql is provided

    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(search_url, headers=headers, params=params)
            response.raise_for_status()
            return response.json().get("issues", [])
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=f"Failed to fetch Jira issues: {e.response.text}")
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {str(e)}")

@router.post("/jira/issue")
async def create_jira_issue(
    issue: JiraIssueCreate,
    access_token: Annotated[str, Depends(get_jira_access_token)]
):
    """
    Creates a new Jira issue.
    """
    create_url = f"{JIRA_SITE_URL}/rest/api/3/issue"
    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json",
        "Accept": "application/json",
    }
    payload = {
        "fields": {
            "project": {
                "key": issue.project_key
            },
            "summary": issue.summary,
            "issuetype": {
                "name": issue.issue_type
            }
        }
    }
    if issue.description:
        payload["fields"]["description"] = {
            "type": "doc",
            "version": 1,
            "content": [
                {
                    "type": "paragraph",
                    "content": [
                        {
                            "type": "text",
                            "text": issue.description
                        }
                    ]
                }
            ]
        }

    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(create_url, headers=headers, json=payload)
            response.raise_for_status()
            return response.json()
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=f"Failed to create Jira issue: {e.response.text}")
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {str(e)}")

@router.put("/jira/issue/{issue_id}")
async def update_jira_issue(
    issue_id: str,
    issue_update: JiraIssueUpdate,
    access_token: Annotated[str, Depends(get_jira_access_token)]
):
    """
    Updates an existing Jira issue.
    """
    update_url = f"{JIRA_SITE_URL}/rest/api/3/issue/{issue_id}"
    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json",
        "Accept": "application/json",
    }
    payload = {"fields": {}}
    if issue_update.summary:
        payload["fields"]["summary"] = issue_update.summary
    if issue_update.description:
        payload["fields"]["description"] = {
            "type": "doc",
            "version": 1,
            "content": [
                {
                    "type": "paragraph",
                    "content": [
                        {
                            "type": "text",
                            "text": issue_update.description
                        }
                    ]
                }
            ]
        }
    if issue_update.status:
        # Transition issue to new status
        transitions_url = f"{JIRA_SITE_URL}/rest/api/3/issue/{issue_id}/transitions"
        transition_payload = {"transition": {"id": issue_update.status}} # Assuming status is transition ID or name
        async with httpx.AsyncClient() as client:
            transition_response = await client.post(transitions_url, headers=headers, json=transition_payload)
            transition_response.raise_for_status()
        
    async with httpx.AsyncClient() as client:
        try:
            response = await client.put(update_url, headers=headers, json=payload)
            response.raise_for_status()
            return response.json()
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=f"Failed to update Jira issue: {e.response.text}")
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {str(e)}")

@router.delete("/jira/issue/{issue_id}")
async def delete_jira_issue(
    issue_id: str,
    access_token: Annotated[str, Depends(get_jira_access_token)]
):
    """
    Deletes a Jira issue.
    """
    delete_url = f"{JIRA_SITE_URL}/rest/api/3/issue/{issue_id}"
    headers = {
        "Authorization": f"Bearer {access_token}",
    }
    async with httpx.AsyncClient() as client:
        try:
            response = await client.delete(delete_url, headers=headers)
            response.raise_for_status()
            return {"message": "Issue deleted successfully!"}
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=f"Failed to delete Jira issue: {e.response.text}")
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {str(e)}")
