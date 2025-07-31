from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
import models

router = APIRouter()

@router.post("/messages/")
def create_message(message: models.MessageCreate, db: Session = Depends(get_db)):
    db_message = models.Message(**message.dict())
    db.add(db_message)
    db.commit()
    db.refresh(db_message)
    return db_message

@router.get("/messages/{chat_id}")
def get_messages(chat_id: int, db: Session = Depends(get_db)):
    return db.query(models.Message).filter(models.Message.chat_id == chat_id).all()