from sqlmodel import Session, select
from . import models, coding_schemas

def get_code_file(db: Session, code_file_id: int):
    return db.get(models.CodeFile, code_file_id)

def get_code_files(db: Session, user_id: int, skip: int = 0, limit: int = 100):
    return db.exec(select(models.CodeFile).where(models.CodeFile.user_id == user_id).offset(skip).limit(limit)).all()

def create_code_file(db: Session, code_file: coding_schemas.CodeFileCreate, user_id: int):
    db_code_file = models.CodeFile(**code_file.dict(), user_id=user_id)
    db.add(db_code_file)
    db.commit()
    db.refresh(db_code_file)
    return db_code_file

def update_code_file(db: Session, code_file_id: int, code_file: coding_schemas.CodeFileCreate):
    db_code_file = db.get(models.CodeFile, code_file_id)
    if not db_code_file:
        return None
    code_file_data = code_file.dict(exclude_unset=True)
    for key, value in code_file_data.items():
        setattr(db_code_file, key, value)
    db.add(db_code_file)
    db.commit()
    db.refresh(db_code_file)
    return db_code_file

def delete_code_file(db: Session, code_file_id: int):
    code_file = db.get(models.CodeFile, code_file_id)
    if not code_file:
        return None
    db.delete(code_file)
    db.commit()
    return {"ok": True}
