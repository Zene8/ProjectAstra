
from fastapi import APIRouter, Depends, HTTPException, Request
from sqlmodel import Session
from google.auth.transport.requests import Request as GoogleAuthRequest
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import Flow
from googleapiclient.discovery import build

from database import get_session
from . import tasks_crud, tasks_schemas
from .auth import get_current_user
from models import User

router = APIRouter()

# Google Tasks API scopes
SCOPES = ['https://www.googleapis.com/auth/tasks']

@router.get("/google_tasks_auth")
async def google_tasks_auth(request: Request):
    flow = Flow.from_client_secrets_file(
        'client_secret.json', scopes=SCOPES, redirect_uri=str(request.url_for('google_tasks_auth_callback'))
    )
    authorization_url, state = flow.authorization_url(access_type='offline', include_granted_scopes='true')
    return {"authorization_url": authorization_url, "state": state}

@router.get("/google_tasks_auth_callback")
async def google_tasks_auth_callback(request: Request, state: str, code: str, db: Session = Depends(get_session), user: User = Depends(get_current_user)):
    flow = Flow.from_client_secrets_file(
        'client_secret.json', scopes=SCOPES, state=state, redirect_uri=str(request.url_for('google_tasks_auth_callback'))
    )
    flow.fetch_token(code=code)
    credentials = flow.credentials

    user.google_credentials = credentials.to_json()
    db.add(user)
    db.commit()
    db.refresh(user)

    return {"message": "Google Tasks connected successfully!"}

@router.post("/users/{user_id}/tasks/", response_model=tasks_schemas.Task)
def create_task_for_user(
    user_id: int, task: tasks_schemas.TaskCreate, db: Session = Depends(get_session)
):
    return tasks_crud.create_task(db=db, task=task, user_id=user_id)


@router.get("/users/{user_id}/tasks/", response_model=list[tasks_schemas.Task])
def read_tasks(
    user_id: int, skip: int = 0, limit: int = 100, db: Session = Depends(get_session)
):
    tasks = tasks_crud.get_tasks(db, user_id=user_id, skip=skip, limit=limit)
    return tasks

@router.get("/tasks/google/tasks") # Changed path
async def get_google_tasks(db: Session = Depends(get_session), user: User = Depends(get_current_user)):
    if not user.google_credentials:
        raise HTTPException(status_code=401, detail="Google account not linked")

    credentials = Credentials.from_authorized_user_info(user.google_credentials)

    if credentials.expired and credentials.refresh_token:
        credentials.refresh(GoogleAuthRequest())

    service = build('tasks', 'v1', credentials=credentials)

    results = service.tasks().list(tasklist='@default', maxResults=10).execute()
    items = results.get('items', [])

    task_list = []
    for item in items:
        task_list.append({
            "id": item['id'],
            "title": item['title'],
            "isDone": item['status'] == 'completed',
            "dueDate": item.get('due') # Google Tasks API returns 'due'
        })
    return task_list # Return list directly

@router.post("/tasks/google/tasks") # Changed path
async def create_google_task(task: tasks_schemas.GoogleTask, db: Session = Depends(get_session), user: User = Depends(get_current_user)):
    if not user.google_credentials:
        raise HTTPException(status_code=401, detail="Google account not linked")

    credentials = Credentials.from_authorized_user_info(user.google_credentials)

    if credentials.expired and credentials.refresh_token:
        credentials.refresh(GoogleAuthRequest())

    service = build('tasks', 'v1', credentials=credentials)

    created_task = service.tasks().insert(tasklist='@default', body=task.dict()).execute()
    return { # Return a dictionary matching the Task model
        "id": created_task['id'],
        "title": created_task['title'],
        "isDone": created_task['status'] == 'completed',
        "dueDate": created_task.get('due')
    }

@router.put("/tasks/google/tasks/{list_id}/{task_id}") # Changed path
async def update_google_task(list_id: str, task_id: str, task: tasks_schemas.GoogleTask, db: Session = Depends(get_session), user: User = Depends(get_current_user)):
    if not user.google_credentials:
        raise HTTPException(status_code=401, detail="Google account not linked")

    credentials = Credentials.from_authorized_user_info(user.google_credentials)

    if credentials.expired and credentials.refresh_token:
        credentials.refresh(GoogleAuthRequest())

    service = build('tasks', 'v1', credentials=credentials)

    updated_task = service.tasks().update(tasklist=list_id, task=task_id, body=task.dict()).execute()
    return { # Return a dictionary matching the Task model
        "id": updated_task['id'],
        "title": updated_task['title'],
        "isDone": updated_task['status'] == 'completed',
        "dueDate": updated_task.get('due')
    }

@router.delete("/tasks/google/tasks/{list_id}/{task_id}") # Changed path
async def delete_google_task(list_id: str, task_id: str, db: Session = Depends(get_session), user: User = Depends(get_current_user)):
    if not user.google_credentials:
        raise HTTPException(status_code=401, detail="Google account not linked")

    credentials = Credentials.from_authorized_user_info(user.google_credentials)

    if credentials.expired and credentials.refresh_token:
        credentials.refresh(GoogleAuthRequest())

    service = build('tasks', 'v1', credentials=credentials)

    service.tasks().delete(tasklist=list_id, task=task_id).execute()
    return {"message": "Task deleted successfully"}

@router.get("/tasks/google/tasklists") # New endpoint for task lists
async def get_google_task_lists(db: Session = Depends(get_session), user: User = Depends(get_current_user)):
    if not user.google_credentials:
        raise HTTPException(status_code=401, detail="Google account not linked")

    credentials = Credentials.from_authorized_user_info(user.google_credentials)

    if credentials.expired and credentials.refresh_token:
        credentials.refresh(GoogleAuthRequest())

    service = build('tasks', 'v1', credentials=credentials)

    results = service.tasklists().list().execute()
    items = results.get('items', [])
    
    task_lists = []
    for item in items:
        task_lists.append({
            "id": item['id'],
            "title": item['title']
        })
    return task_lists

@router.put("/users/{user_id}/tasks/{task_id}", response_model=tasks_schemas.Task)
def update_task_for_user(
    user_id: int, task_id: int, task: tasks_schemas.TaskCreate, db: Session = Depends(get_session)
):
    db_task = tasks_crud.update_task(db=db, task_id=task_id, task=task)
    if db_task is None:
        raise HTTPException(status_code=404, detail="Task not found")
    return db_task

@router.delete("/users/{user_id}/tasks/{task_id}")
def delete_task_for_user(
    user_id: int, task_id: int, db: Session = Depends(get_session)
):
    result = tasks_crud.delete_task(db=db, task_id=task_id)
    if result is None:
        raise HTTPException(status_code=404, detail="Task not found")
    return result
