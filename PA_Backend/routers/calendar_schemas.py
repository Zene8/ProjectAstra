from pydantic import BaseModel
import datetime

class CalendarEventBase(BaseModel):
    title: str
    start_time: datetime.datetime
    end_time: datetime.datetime

class CalendarEventCreate(CalendarEventBase):
    pass

class CalendarEvent(CalendarEventBase):
    id: int
    user_id: int

    class Config:
        orm_mode = True
