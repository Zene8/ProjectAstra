from fastapi import APIRouter, Depends, HTTPException, status, File, UploadFile
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlmodel import Session, select
from jose import JWTError, jwt
import pandas as pd
import io

from .. import models
from ..database import get_session
from .finance import crud, schemas, security

router = APIRouter()

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/finance/token")

async def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_session)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, security.SECRET_KEY, algorithms=[security.ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
        token_data = schemas.TokenData(username=username)
    except JWTError:
        raise credentials_exception
    user = crud.get_user_by_username(db, username=token_data.username)
    if user is None:
        raise credentials_exception
    return user

@router.post("/token", response_model=schemas.Token)
async def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_session)):
    user = crud.get_user_by_username(db, username=form_data.username)
    if not user or not security.verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token = security.create_access_token(
        data={"sub": user.username}
    )
    return {"access_token": access_token, "token_type": "bearer"}

@router.post("/users/", response_model=schemas.User)
async def create_user(user: schemas.UserCreate, db: Session = Depends(get_session)):
    db_user = crud.get_user_by_username(db, username=user.username)
    if db_user:
        raise HTTPException(status_code=400, detail="Username already registered")
    return crud.create_user(db=db, user=user)

@router.get("/users/me/", response_model=schemas.User)
async def read_users_me(current_user: schemas.User = Depends(get_current_user)):
    return current_user

@router.post("/users/me/transactions/", response_model=schemas.Transaction)
async def create_transaction_for_user(
    transaction: schemas.TransactionCreate,
    current_user: schemas.User = Depends(get_current_user),
    db: Session = Depends(get_session)
):
    return crud.create_transaction(db=db, transaction=transaction, user_id=current_user.id)

@router.get("/users/me/transactions/", response_model=list[schemas.Transaction])
async def read_transactions_for_user(
    skip: int = 0,
    limit: int = 100,
    current_user: schemas.User = Depends(get_current_user),
    db: Session = Depends(get_session)
):
    return crud.get_transactions(db=db, user_id=current_user.id, skip=skip, limit=limit)

@router.post("/users/me/transactions/upload_csv/")
async def create_upload_file(
    file: UploadFile = File(...),
    current_user: schemas.User = Depends(get_current_user),
    db: Session = Depends(get_session)
):
    if file.content_type != 'text/csv':
        raise HTTPException(status_code=400, detail="Invalid file type")

    contents = await file.read()

    # In-memory file-like object
    csv_file = io.StringIO(contents.decode('utf-8'))

    try:
        transactions = crud.create_transactions_from_csv(db=db, user_id=current_user.id, file=csv_file)
        return {"message": f"{len(transactions)} transactions uploaded successfully"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error processing CSV file: {e}")
