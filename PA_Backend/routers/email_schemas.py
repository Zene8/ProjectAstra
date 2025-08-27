from pydantic import BaseModel
import datetime

class EmailBase(BaseModel):
    subject: str
    sender: str
    recipients: str
    body: str

class EmailCreate(EmailBase):
    pass

class Email(EmailBase):
    id: int
    timestamp: datetime.datetime
    user_id: int

    class Config:
        orm_mode = True
