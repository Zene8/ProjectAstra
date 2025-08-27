from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session

from database import get_session
from . import coding_crud, coding_schemas
from .auth import get_current_user
from models import User

router = APIRouter()

@router.post("/users/{user_id}/code_files/", response_model=coding_schemas.CodeFile)
def create_code_file_for_user(
    user_id: int, code_file: coding_schemas.CodeFileCreate, db: Session = Depends(get_session)
):
    return coding_crud.create_code_file(db=db, code_file=code_file, user_id=user_id)

@router.get("/users/{user_id}/code_files/", response_model=list[coding_schemas.CodeFile])
def read_code_files(
    user_id: int, skip: int = 0, limit: int = 100, db: Session = Depends(get_session)
):
    code_files = coding_crud.get_code_files(db, user_id=user_id, skip=skip, limit=limit)
    return code_files

@router.put("/users/{user_id}/code_files/{code_file_id}", response_model=coding_schemas.CodeFile)
def update_code_file_for_user(
    user_id: int, code_file_id: int, code_file: coding_schemas.CodeFileCreate, db: Session = Depends(get_session)
):
    db_code_file = coding_crud.update_code_file(db=db, code_file_id=code_file_id, code_file=code_file)
    if db_code_file is None:
        raise HTTPException(status_code=404, detail="Code file not found")
    return db_code_file

@router.delete("/users/{user_id}/code_files/{code_file_id}")
def delete_code_file_for_user(
    user_id: int, code_file_id: int, db: Session = Depends(get_session)
):
    result = coding_crud.delete_code_file(db=db, code_file_id=code_file_id)
    if result is None:
        raise HTTPException(status_code=404, detail="Code file not found")
    return result