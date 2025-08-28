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
TENANT_ID = os.getenv("TODO_TENANT_ID")
CLIENT_ID = os.getenv("TODO_CLIENT_ID")
CLIENT_SECRET = os.getenv("TODO_CLIENT_SECRET")
REDIRECT_URI = os.getenv("TODO_REDIRECT_URI", "http://localhost:5000/api/todo/auth/callback")

AUTHORITY = f"https://login.microsoftonline.com/{TENANT_ID}"
GRAPH_API_ENDPOINT = "https://graph.microsoft.com/v1.0/"
# Scopes required for Microsoft To Do
SCOPE = ["Tasks.ReadWrite", "offline_access", "User.Read"]

class TodoTaskCreate(BaseModel):
    title: str
    due_date: Optional[str] = None # ISO 8601 format

class TodoTaskUpdate(BaseModel):
    title: Optional[str] = None
    is_completed: Optional[bool] = None
    due_date: Optional[str] = None

@router.get("/todo/auth/login")
async def todo_login(user_id: Annotated[int, Depends(get_current_user_id)]):
    """
    Initiates the OAuth2 Authorization Code Flow for Microsoft To Do.
    """
    if not all([TENANT_ID, CLIENT_ID, CLIENT_SECRET]):
        raise HTTPException(status_code=500, detail="Microsoft To Do API credentials not configured.")

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

@router.get("/todo/auth/callback")
async def todo_auth_callback(
    request: Request,
    code: str = None,
    state: str = None,
    error: str = None,
    error_description: str = None,
    session: AsyncSession = Depends(get_session)
):
    """
    Callback endpoint for Microsoft To Do OAuth2 redirect.
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
    
    user.todo_access_token = access_token
    user.todo_refresh_token = refresh_token
    session.add(user)
    await session.commit()
    await session.refresh(user)

    return HTMLResponse("<h1>Microsoft To Do Authentication Successful!</h1><p>You can close this window.</p>")

async def get_todo_access_token(user_id: int, session: AsyncSession) -> str:
    user = (await session.execute(select(User).where(User.id == user_id))).scalars().first()
    if not user or not user.todo_access_token:
        raise HTTPException(status_code=401, detail="Microsoft To Do not authenticated for this user.")
    
    # TODO: Implement token refresh logic if access token is expired
    return user.todo_access_token

@router.get("/todo/task_lists")
async def get_todo_task_lists(access_token: Annotated[str, Depends(get_todo_access_token)]):
    """
    Fetches Microsoft To Do task lists.
    """
    task_lists_url = f"{GRAPH_API_ENDPOINT}me/todo/lists"
    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json",
    }
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(task_lists_url, headers=headers)
            response.raise_for_status()
            return response.json().get("value", [])
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=f"Failed to fetch task lists: {e.response.text}")
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {str(e)}")

@router.get("/todo/tasks/{list_id}")
async def get_todo_tasks(list_id: str, access_token: Annotated[str, Depends(get_todo_access_token)]):
    """
    Fetches tasks from a specific Microsoft To Do task list.
    """
    tasks_url = f"{GRAPH_API_ENDPOINT}me/todo/lists/{list_id}/tasks"
    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json",
    }
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(tasks_url, headers=headers)
            response.raise_for_status()
            return response.json().get("value", [])
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=f"Failed to fetch tasks: {e.response.text}")
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {str(e)}")

@router.post("/todo/tasks/{list_id}")
async def create_todo_task(list_id: str, task: TodoTaskCreate, access_token: Annotated[str, Depends(get_todo_access_token)]):
    """
    Creates a new task in a specific Microsoft To Do task list.
    """
    create_task_url = f"{GRAPH_API_ENDPOINT}me/todo/lists/{list_id}/tasks"
    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json",
    }
    task_payload = {"title": task.title}
    if task.due_date:
        task_payload["dueDateTime"] = {"dateTime": task.due_date, "timeZone": "UTC"} # Assuming UTC for simplicity

    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(create_task_url, headers=headers, json=task_payload)
            response.raise_for_status()
            return response.json()
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=f"Failed to create task: {e.response.text}")
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {str(e)}")

@router.patch("/todo/tasks/{list_id}/{task_id}")
async def update_todo_task(list_id: str, task_id: str, task: TodoTaskUpdate, access_token: Annotated[str, Depends(get_todo_access_token)]):
    """
    Updates an existing task in a specific Microsoft To Do task list.
    """
    update_task_url = f"{GRAPH_API_ENDPOINT}me/todo/lists/{list_id}/tasks/{task_id}"
    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json",
    }
    task_payload = {}
    if task.title:
        task_payload["title"] = task.title
    if task.is_completed is not None:
        task_payload["status"] = "completed" if task.is_completed else "notStarted"
    if task.due_date:
        task_payload["dueDateTime"] = {"dateTime": task.due_date, "timeZone": "UTC"}

    async with httpx.AsyncClient() as client:
        try:
            response = await client.patch(update_task_url, headers=headers, json=task_payload)
            response.raise_for_status()
            return response.json()
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=f"Failed to update task: {e.response.text}")
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {str(e)}")

@router.delete("/todo/tasks/{list_id}/{task_id}")
async def delete_todo_task(list_id: str, task_id: str, access_token: Annotated[str, Depends(get_todo_access_token)]):
    """
    Deletes a task from a specific Microsoft To Do task list.
    """
    delete_task_url = f"{GRAPH_API_ENDPOINT}me/todo/lists/{list_id}/tasks/{task_id}"
    headers = {
        "Authorization": f"Bearer {access_token}",
    }
    async with httpx.AsyncClient() as client:
        try:
            response = await client.delete(delete_task_url, headers=headers)
            response.raise_for_status()
            return {"message": "Task deleted successfully!"}
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=f"Failed to delete task: {e.response.text}")
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {str(e)}")
