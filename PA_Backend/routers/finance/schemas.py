from pydantic import BaseModel
from typing import List, Optional
from datetime import date
from ..models import ExpenseAttributionStatus, InvoiceStatus, RecurringExpenseFrequency

# --- Category Schemas ---
class CategoryBase(BaseModel):
    name: str

class CategoryCreate(CategoryBase):
    pass

class Category(CategoryBase):
    id: int

    class Config:
        orm_mode = True

# --- Transaction Schemas ---
class TransactionBase(BaseModel):
    date: date
    vendor_name: str
    amount: float
    category_id: Optional[int] = None
    account_name: Optional[str] = None
    is_recurring: bool = False

class TransactionCreate(TransactionBase):
    pass

class TransactionRead(TransactionBase):
    id: int
    user_id: int

    class Config:
        orm_mode = True

# --- Asset Schemas ---
class AssetBase(BaseModel):
    name: str
    value: float

class AssetCreate(AssetBase):
    pass

class Asset(AssetBase):
    id: int
    user_id: int

    class Config:
        orm_mode = True

# --- Budget Schemas ---
class BudgetBase(BaseModel):
    category_id: int
    amount_allocated: float
    start_date: date
    end_date: date

class BudgetCreate(BudgetBase):
    pass

class BudgetRead(BudgetBase):
    id: int
    user_id: int

    class Config:
        orm_mode = True

# --- RecurringExpense Schemas ---
class RecurringExpenseBase(BaseModel):
    vendor_name: str
    amount: float
    category_id: int
    frequency: RecurringExpenseFrequency
    next_due_date: date

class RecurringExpenseCreate(RecurringExpenseBase):
    pass

class RecurringExpenseRead(RecurringExpenseBase):
    id: int
    user_id: int

    class Config:
        orm_mode = True

# --- ExpenseAttribution Schemas ---
class ExpenseAttributionBase(BaseModel):
    original_transaction_id: int
    attributed_to_user_id: int
    amount: float

class ExpenseAttributionCreate(ExpenseAttributionBase):
    pass

class ExpenseAttributionRead(ExpenseAttributionBase):
    id: int
    attributing_user_id: int
    status: ExpenseAttributionStatus
    invoice_id: Optional[int] = None

    class Config:
        orm_mode = True

# --- Invoice Schemas ---
class InvoiceBase(BaseModel):
    to_user_id: int
    total_amount: float
    due_date: date
    attributed_expense_ids: List[int]

class InvoiceCreate(InvoiceBase):
    pass

class InvoiceRead(InvoiceBase):
    id: int
    from_user_id: int
    status: InvoiceStatus

    class Config:
        orm_mode = True

# --- User Schemas ---
class UserBase(BaseModel):
    username: str
    email: str

class UserCreate(UserBase):
    password: str

class UserRead(UserBase):
    id: int
    profile_picture_url: Optional[str] = None
    transactions: List[TransactionRead] = []
    assets: List[Asset] = []
    budgets: List[BudgetRead] = []
    recurring_expenses: List[RecurringExpenseRead] = []

    class Config:
        orm_mode = True

# --- Auth Schemas ---
class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    username: Optional[str] = None

# --- Plaid Schemas ---
class PlaidLinkTokenCreateRequest(BaseModel):
    user_id: str

class PlaidPublicTokenExchangeRequest(BaseModel):
    public_token: str