from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
import models

router = APIRouter()

@router.post("/chats/")
def create_chat(db: Session = Depends(get_db)):
    new_chat = models.Chat()
    db.add(new_chat)
    db.commit()
    db.refresh(new_chat)
    return new_chat

@router.get("/chats/")
def get_chats(db: Session = Depends(get_db)):
    return db.query(models.Chat).all()