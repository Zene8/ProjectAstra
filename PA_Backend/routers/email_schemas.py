from pydantic import BaseModel
from typing import Optional, List

class EmailBase(BaseModel):
    subject: str
    body: str

class EmailCreate(EmailBase):
    pass

class Email(EmailBase):
    id: int
    owner_id: int

    class Config:
        orm_mode = True

class GoogleEmail(BaseModel):
    to: List[str]
    subject: str
    message: str