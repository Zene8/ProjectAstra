from sqlmodel import Session, select
from .. import models, schemas, security
import pandas as pd
from datetime import datetime
from ..models import ExpenseAttributionStatus, InvoiceStatus

# --- User CRUD ---
def get_user_by_username(db: Session, username: str):
    return db.exec(select(models.User).where(models.User.username == username)).first()

def get_user(db: Session, user_id: int):
    return db.get(models.User, user_id)

def create_user(db: Session, user: schemas.UserCreate):
    hashed_password = security.get_password_hash(user.password)
    db_user = models.User(username=user.username, email=user.email, hashed_password=hashed_password)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def set_plaid_access_token(db: Session, user_id: int, plaid_access_token: str, plaid_item_id: str):
    user = db.get(models.User, user_id)
    if not user:
        return None
    user.plaid_access_token = plaid_access_token
    user.plaid_item_id = plaid_item_id
    db.add(user)
    db.commit()
    db.refresh(user)
    return user

# --- Transaction CRUD ---
def create_transaction(db: Session, transaction: schemas.TransactionCreate, user_id: int):
    db_transaction = models.Transaction(**transaction.dict(), user_id=user_id)
    db.add(db_transaction)
    db.commit()
    db.refresh(db_transaction)
    return db_transaction

def get_transactions(db: Session, user_id: int, skip: int = 0, limit: int = 100):
    return db.exec(select(models.Transaction).where(models.Transaction.user_id == user_id).offset(skip).limit(limit)).all()

def update_transaction(db: Session, transaction_id: int, transaction: schemas.TransactionCreate):
    db_transaction = db.get(models.Transaction, transaction_id)
    if not db_transaction:
        return None
    transaction_data = transaction.dict(exclude_unset=True)
    for key, value in transaction_data.items():
        setattr(db_transaction, key, value)
    db.add(db_transaction)
    db.commit()
    db.refresh(db_transaction)
    return db_transaction

def delete_transaction(db: Session, transaction_id: int):
    transaction = db.get(models.Transaction, transaction_id)
    if not transaction:
        return None
    db.delete(transaction)
    db.commit()
    return {"ok": True}

def create_transactions_from_csv(db: Session, user_id: int, file):
    df = pd.read_csv(file)
    transactions = []
    # A simple way to map CSV columns to our schema. This should be made more robust.
    # Assumes columns 'Date', 'Description', 'Amount'
    for _, row in df.iterrows():
        transaction_data = schemas.TransactionCreate(
            date=datetime.strptime(row['Date'], '%Y-%m-%d').date(),
            vendor_name=row['Description'],
            amount=row['Amount']
        )
        db_transaction = models.Transaction(**transaction_data.dict(), user_id=user_id)
        db.add(db_transaction)
        transactions.append(db_transaction)
    db.commit()
    for transaction in transactions:
        db.refresh(transaction)
    return transactions

# --- Asset CRUD ---
def create_asset(db: Session, asset: schemas.AssetCreate, user_id: int):
    db_asset = models.Asset(**asset.dict(), user_id=user_id)
    db.add(db_asset)
    db.commit()
    db.refresh(db_asset)
    return db_asset

def get_assets(db: Session, user_id: int, skip: int = 0, limit: int = 100):
    return db.exec(select(models.Asset).where(models.Asset.user_id == user_id).offset(skip).limit(limit)).all()

# --- Category CRUD ---
def create_category(db: Session, category: schemas.CategoryCreate):
    db_category = models.Category(**category.dict())
    db.add(db_category)
    db.commit()
    db.refresh(db_category)
    return db_category

def get_categories(db: Session, skip: int = 0, limit: int = 100):
    return db.exec(select(models.Category).offset(skip).limit(limit)).all()

# --- Budget CRUD ---
def create_budget(db: Session, budget: schemas.BudgetCreate, user_id: int):
    db_budget = models.Budget(**budget.dict(), user_id=user_id)
    db.add(db_budget)
    db.commit()
    db.refresh(db_budget)
    return db_budget

def get_budgets(db: Session, user_id: int, skip: int = 0, limit: int = 100):
    return db.exec(select(models.Budget).where(models.Budget.user_id == user_id).offset(skip).limit(limit)).all()

# --- RecurringExpense CRUD ---
def create_recurring_expense(db: Session, expense: schemas.RecurringExpenseCreate, user_id: int):
    db_expense = models.RecurringExpense(**expense.dict(), user_id=user_id)
    db.add(db_expense)
    db.commit()
    db.refresh(db_expense)
    return db_expense

def get_recurring_expenses(db: Session, user_id: int, skip: int = 0, limit: int = 100):
    return db.exec(select(models.RecurringExpense).where(models.RecurringExpense.user_id == user_id).offset(skip).limit(limit)).all()

# --- ExpenseAttribution CRUD ---
def create_expense_attribution(db: Session, attribution: schemas.ExpenseAttributionCreate, attributing_user_id: int):
    db_attribution = models.ExpenseAttribution(**attribution.dict(), attributing_user_id=attributing_user_id)
    db.add(db_attribution)
    db.commit()
    db.refresh(db_attribution)
    return db_attribution

def get_expense_attribution(db: Session, attribution_id: int):
    return db.get(models.ExpenseAttribution, attribution_id)

def approve_expense_attribution(db: Session, attribution_id: int):
    db_attribution = db.get(models.ExpenseAttribution, attribution_id)
    if not db_attribution:
        return None
    db_attribution.status = ExpenseAttributionStatus.APPROVED
    db.add(db_attribution)
    db.commit()
    db.refresh(db_attribution)
    return db_attribution

# --- Invoice CRUD ---
def create_invoice(db: Session, invoice: schemas.InvoiceCreate, from_user_id: int):
    db_invoice = models.Invoice(
        from_user_id=from_user_id,
        to_user_id=invoice.to_user_id,
        total_amount=invoice.total_amount,
        due_date=invoice.due_date,
        status=InvoiceStatus.UNPAID
    )
    # Link attributed expenses
    for expense_id in invoice.attributed_expense_ids:
        expense = db.get(models.ExpenseAttribution, expense_id)
        if expense and expense.attributed_to_user_id == invoice.to_user_id and expense.status == ExpenseAttributionStatus.APPROVED:
            db_invoice.attributed_expenses.append(expense)
    
    db.add(db_invoice)
    db.commit()
    db.refresh(db_invoice)
    return db_invoice

def get_invoices(db: Session, user_id: int):
    return db.exec(select(models.Invoice).where(
        (models.Invoice.from_user_id == user_id) | (models.Invoice.to_user_id == user_id)
    )).all()