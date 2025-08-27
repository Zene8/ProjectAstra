from sqlmodel import Session, select
from . import models, documents_schemas

def get_document(db: Session, document_id: int):
    return db.get(models.Document, document_id)

def get_documents(db: Session, user_id: int, skip: int = 0, limit: int = 100):
    return db.exec(select(models.Document).where(models.Document.user_id == user_id).offset(skip).limit(limit)).all()

def create_document(db: Session, document: documents_schemas.DocumentCreate, user_id: int):
    db_document = models.Document(**document.dict(), user_id=user_id)
    db.add(db_document)
    db.commit()
    db.refresh(db_document)
    return db_document

def update_document(db: Session, document_id: int, document: documents_schemas.DocumentCreate):
    db_document = db.get(models.Document, document_id)
    if not db_document:
        return None
    document_data = document.dict(exclude_unset=True)
    for key, value in document_data.items():
        setattr(db_document, key, value)
    db.add(db_document)
    db.commit()
    db.refresh(db_document)
    return db_document

def delete_document(db: Session, document_id: int):
    document = db.get(models.Document, document_id)
    if not document:
        return None
    db.delete(document)
    db.commit()
    return {"ok": True}
