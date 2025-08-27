from sqlmodel import Session, select
from . import models, email_schemas

def get_email(db: Session, email_id: int):
    return db.get(models.Email, email_id)

def get_emails(db: Session, user_id: int, skip: int = 0, limit: int = 100):
    return db.exec(select(models.Email).where(models.Email.user_id == user_id).offset(skip).limit(limit)).all()

def create_email(db: Session, email: email_schemas.EmailCreate, user_id: int):
    db_email = models.Email(**email.dict(), user_id=user_id)
    db.add(db_email)
    db.commit()
    db.refresh(db_email)
    return db_email

def update_email(db: Session, email_id: int, email: email_schemas.EmailCreate):
    db_email = db.get(models.Email, email_id)
    if not db_email:
        return None
    email_data = email.dict(exclude_unset=True)
    for key, value in email_data.items():
        setattr(db_email, key, value)
    db.add(db_email)
    db.commit()
    db.refresh(db_email)
    return db_email

def delete_email(db: Session, email_id: int):
    email = db.get(models.Email, email_id)
    if not email:
        return None
    db.delete(email)
    db.commit()
    return {"ok": True}
