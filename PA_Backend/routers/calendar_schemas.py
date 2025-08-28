from pydantic import BaseModel
from typing import Optional
import datetime

class CalendarEventBase(BaseModel):
    title: str
    description: Optional[str] = None
    start_time: datetime.datetime
    end_time: datetime.datetime

class CalendarEventCreate(CalendarEventBase):
    pass

class CalendarEvent(CalendarEventBase):
    id: int
    owner_id: int

    class Config:
        orm_mode = True

class GoogleCalendarEvent(BaseModel):
    summary: str
    description: Optional[str] = None
    start: dict
    end: dict