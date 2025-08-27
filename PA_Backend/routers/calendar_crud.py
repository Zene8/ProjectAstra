from sqlmodel import Session, select
from . import models, calendar_schemas

def get_calendar_event(db: Session, event_id: int):
    return db.get(models.CalendarEvent, event_id)

def get_calendar_events(db: Session, user_id: int, skip: int = 0, limit: int = 100):
    return db.exec(select(models.CalendarEvent).where(models.CalendarEvent.user_id == user_id).offset(skip).limit(limit)).all()

def create_calendar_event(db: Session, event: calendar_schemas.CalendarEventCreate, user_id: int):
    db_event = models.CalendarEvent(**event.dict(), user_id=user_id)
    db.add(db_event)
    db.commit()
    db.refresh(db_event)
    return db_event
