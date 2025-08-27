from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session

from database import get_session
from . import documents_crud, documents_schemas
from .auth import get_current_user
from models import User

router = APIRouter()

@router.post("/users/{user_id}/documents/", response_model=documents_schemas.Document)
def create_document_for_user(
    user_id: int, document: documents_schemas.DocumentCreate, db: Session = Depends(get_session)
):
    return documents_crud.create_document(db=db, document=document, user_id=user_id)

@router.get("/users/{user_id}/documents/", response_model=list[documents_schemas.Document])
def read_documents(
    user_id: int, skip: int = 0, limit: int = 100, db: Session = Depends(get_session)
):
    documents = documents_crud.get_documents(db, user_id=user_id, skip=skip, limit=limit)
    return documents

@router.put("/users/{user_id}/documents/{document_id}", response_model=documents_schemas.Document)
def update_document_for_user(
    user_id: int, document_id: int, document: documents_schemas.DocumentCreate, db: Session = Depends(get_session)
):
    db_document = documents_crud.update_document(db=db, document_id=document_id, document=document)
    if db_document is None:
        raise HTTPException(status_code=404, detail="Document not found")
    return db_document

@router.delete("/users/{user_id}/documents/{document_id}")
def delete_document_for_user(
    user_id: int, document_id: int, db: Session = Depends(get_session)
):
    result = documents_crud.delete_document(db=db, document_id=document_id)
    if result is None:
        raise HTTPException(status_code=404, detail="Document not found")
    return result