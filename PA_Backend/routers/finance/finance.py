from fastapi import APIRouter, Depends, HTTPException, status, File, UploadFile
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlmodel import Session, select
from jose import JWTError, jwt
import pandas as pd
import io

from .. import models
from ..database import get_session
from . import crud, schemas, security

router = APIRouter(
    prefix="/finance",
    tags=["finance"],
)

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

@router.post("/users/", response_model=schemas.UserRead)
async def create_user(user: schemas.UserCreate, db: Session = Depends(get_session)):
    db_user = crud.get_user_by_username(db, username=user.username)
    if db_user:
        raise HTTPException(status_code=400, detail="Username already registered")
    return crud.create_user(db=db, user=user)

@router.get("/users/me/", response_model=schemas.UserRead)
async def read_users_me(current_user: models.User = Depends(get_current_user)):
    return current_user

# --- Transaction Endpoints ---
@router.post("/transactions/", response_model=schemas.TransactionRead)
async def create_transaction_for_user(
    transaction: schemas.TransactionCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_session)
):
    return crud.create_transaction(db=db, transaction=transaction, user_id=current_user.id)

@router.get("/transactions/", response_model=list[schemas.TransactionRead])
async def read_transactions_for_user(
    skip: int = 0,
    limit: int = 100,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_session)
):
    return crud.get_transactions(db=db, user_id=current_user.id, skip=skip, limit=limit)

@router.post("/transactions/import/csv")
async def create_upload_file(
    file: UploadFile = File(...),
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_session)
):
    if file.content_type != 'text/csv':
        raise HTTPException(status_code=400, detail="Invalid file type")
    try:
        contents = await file.read()
        csv_file = io.StringIO(contents.decode('utf-8'))
        transactions = crud.create_transactions_from_csv(db=db, user_id=current_user.id, file=csv_file)
        return {"message": f"{len(transactions)} transactions uploaded successfully"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error processing CSV file: {e}")

# --- Budget Endpoints ---
@router.post("/budgets/", response_model=schemas.BudgetRead)
async def create_budget(
    budget: schemas.BudgetCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_session)
):
    return crud.create_budget(db=db, budget=budget, user_id=current_user.id)

@router.get("/budgets/", response_model=list[schemas.BudgetRead])
async def read_budgets(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_session)
):
    return crud.get_budgets(db=db, user_id=current_user.id)

# --- Recurring Expense Endpoints ---
@router.post("/recurring-expenses/", response_model=schemas.RecurringExpenseRead)
async def create_recurring_expense(
    expense: schemas.RecurringExpenseCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_session)
):
    return crud.create_recurring_expense(db=db, expense=expense, user_id=current_user.id)

@router.get("/recurring-expenses/", response_model=list[schemas.RecurringExpenseRead])
async def read_recurring_expenses(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_session)
):
    return crud.get_recurring_expenses(db=db, user_id=current_user.id)

# --- Collaborative Finance Endpoints ---
@router.post("/attributions/", response_model=schemas.ExpenseAttributionRead)
async def create_expense_attribution(
    attribution: schemas.ExpenseAttributionCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_session)
):
    return crud.create_expense_attribution(db=db, attribution=attribution, attributing_user_id=current_user.id)

@router.put("/attributions/{attribution_id}/approve", response_model=schemas.ExpenseAttributionRead)
async def approve_expense_attribution(
    attribution_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_session)
):
    db_attribution = crud.get_expense_attribution(db, attribution_id)
    if not db_attribution or db_attribution.attributed_to_user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Expense attribution not found or not authorized")
    return crud.approve_expense_attribution(db=db, attribution_id=attribution_id)

@router.post("/invoices/", response_model=schemas.InvoiceRead)
async def create_invoice(
    invoice: schemas.InvoiceCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_session)
):
    return crud.create_invoice(db=db, invoice=invoice, from_user_id=current_user.id)

@router.get("/invoices/", response_model=list[schemas.InvoiceRead])
async def read_invoices(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_session)
):
    return crud.get_invoices(db=db, user_id=current_user.id)