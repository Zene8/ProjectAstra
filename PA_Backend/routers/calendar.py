
from fastapi import APIRouter, Depends, HTTPException, Request
from sqlmodel import Session
from google.auth.transport.requests import Request as GoogleAuthRequest
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import Flow
from googleapiclient.discovery import build
import datetime

from database import get_session
from . import calendar_crud, calendar_schemas
from .auth import get_current_user
from models import User

router = APIRouter()

# Google Calendar API scopes
SCOPES = ['https://www.googleapis.com/auth/calendar']

@router.get("/google_calendar_auth")
async def google_calendar_auth(request: Request):
    flow = Flow.from_client_secrets_file(
        'client_secret.json', scopes=SCOPES, redirect_uri=str(request.url_for('google_calendar_auth_callback'))
    )
    authorization_url, state = flow.authorization_url(access_type='offline', include_granted_scopes='true')
    return {"authorization_url": authorization_url, "state": state}

@router.get("/google_calendar_auth_callback")
async def google_calendar_auth_callback(request: Request, state: str, code: str, db: Session = Depends(get_session), user: User = Depends(get_current_user)):
    flow = Flow.from_client_secrets_file(
        'client_secret.json', scopes=SCOPES, state=state, redirect_uri=str(request.url_for('google_calendar_auth_callback'))
    )
    flow.fetch_token(code=code)
    credentials = flow.credentials

    user.google_credentials = credentials.to_json()
    db.add(user)
    db.commit()
    db.refresh(user)

    return {"message": "Google Calendar connected successfully!"}

@router.post("/users/{user_id}/events/", response_model=calendar_schemas.CalendarEvent)
def create_event_for_user(
    user_id: int, event: calendar_schemas.CalendarEventCreate, db: Session = Depends(get_session)
):
    return calendar_crud.create_calendar_event(db=db, event=event, user_id=user_id)


@router.get("/users/{user_id}/events/", response_model=list[calendar_schemas.CalendarEvent])
def read_events(
    user_id: int, skip: int = 0, limit: int = 100, db: Session = Depends(get_session)
):
    events = calendar_crud.get_calendar_events(db, user_id=user_id, skip=skip, limit=limit)
    return events

@router.get("/users/{user_id}/google_events/")
async def get_google_events(user_id: int, db: Session = Depends(get_session), user: User = Depends(get_current_user)):
    if not user.google_credentials:
        raise HTTPException(status_code=401, detail="Google account not linked")

    credentials = Credentials.from_authorized_user_info(user.google_credentials)

    if credentials.expired and credentials.refresh_token:
        credentials.refresh(GoogleAuthRequest())

    service = build('calendar', 'v3', credentials=credentials)

    now = datetime.datetime.utcnow().isoformat() + 'Z'
    events_result = service.events().list(
        calendarId='primary', timeMin=now,
        maxResults=10, singleEvents=True,
        orderBy='startTime').execute()
    events = events_result.get('items', [])

    return {"events": events}

@router.post("/users/{user_id}/google_events/")
async def create_google_event(user_id: int, event: calendar_schemas.GoogleCalendarEvent, db: Session = Depends(get_session), user: User = Depends(get_current_user)):
    if not user.google_credentials:
        raise HTTPException(status_code=401, detail="Google account not linked")

    credentials = Credentials.from_authorized_user_info(user.google_credentials)

    if credentials.expired and credentials.refresh_token:
        credentials.refresh(GoogleAuthRequest())

    service = build('calendar', 'v3', credentials=credentials)

    event = service.events().insert(calendarId='primary', body=event.dict()).execute()
    return {"event": event}

@router.put("/users/{user_id}/google_events/{event_id}")
async def update_google_event(user_id: int, event_id: str, event: calendar_schemas.GoogleCalendarEvent, db: Session = Depends(get_session), user: User = Depends(get_current_user)):
    if not user.google_credentials:
        raise HTTPException(status_code=401, detail="Google account not linked")

    credentials = Credentials.from_authorized_user_info(user.google_credentials)

    if credentials.expired and credentials.refresh_token:
        credentials.refresh(GoogleAuthRequest())

    service = build('calendar', 'v3', credentials=credentials)

    updated_event = service.events().update(calendarId='primary', eventId=event_id, body=event.dict()).execute()
    return {"event": updated_event}

@router.delete("/users/{user_id}/google_events/{event_id}")
async def delete_google_event(user_id: int, event_id: str, db: Session = Depends(get_session), user: User = Depends(get_current_user)):
    if not user.google_credentials:
        raise HTTPException(status_code=401, detail="Google account not linked")

    credentials = Credentials.from_authorized_user_info(user.google_credentials)

    if credentials.expired and credentials.refresh_token:
        credentials.refresh(GoogleAuthRequest())

    service = build('calendar', 'v3', credentials=credentials)

    service.events().delete(calendarId='primary', eventId=event_id).execute()
    return {"message": "Event deleted successfully"}
