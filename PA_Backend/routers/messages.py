from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select
from database import get_session
import models

router = APIRouter()

@router.post("/messages/")
def create_message(message: models.MessageCreate, db: Session = Depends(get_session)):
    db_message = models.Message(**message.dict())
    db.add(db_message)
    db.commit()
    db.refresh(db_message)
    return db_message

@router.get("/messages/{chat_id}")
def get_messages(chat_id: int, db: Session = Depends(get_session)):
    return db.exec(select(models.Message).where(models.Message.chat_id == chat_id)).all()

@router.put("/messages/{message_id}")
def update_message(message_id: int, message: models.MessageCreate, db: Session = Depends(get_session)):
    db_message = db.get(models.Message, message_id)
    if not db_message:
        raise HTTPException(status_code=404, detail="Message not found")
    message_data = message.dict(exclude_unset=True)
    for key, value in message_data.items():
        setattr(db_message, key, value)
    db.add(db_message)
    db.commit()
    db.refresh(db_message)
    return db_message

@router.delete("/messages/{message_id}")
def delete_message(message_id: int, db: Session = Depends(get_session)):
    message = db.get(models.Message, message_id)
    if not message:
        raise HTTPException(status_code=404, detail="Message not found")
    db.delete(message)
    db.commit()
    return {"ok": True}