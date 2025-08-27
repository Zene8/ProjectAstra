from typing import Optional, List
from pydantic import BaseModel
from sqlmodel import Field, SQLModel, Relationship
import datetime
from datetime import date
from enum import Enum

class User(SQLModel, table=True):
    __tablename__ = 'user'
    id: Optional[int] = Field(default=None, primary_key=True)
    username: Optional[str] = Field(index=True, unique=True, default=None)
    email: str = Field(index=True, unique=True)
    hashed_password: Optional[str] = Field(default=None)
    google_credentials: Optional[str] = Field(default=None)
    profile_picture_url: Optional[str] = Field(default=None)
    created_at: datetime.datetime = Field(default_factory=datetime.datetime.utcnow)

    # Finance module additions
    plaid_access_token: Optional[str] = Field(default=None)
    plaid_item_id: Optional[str] = Field(default=None)

    messages: List["Message"] = Relationship(back_populates="user")
    transactions: List["Transaction"] = Relationship(back_populates="owner")
    assets: List["Asset"] = Relationship(back_populates="owner")
    budgets: List["Budget"] = Relationship(back_populates="user")
    recurring_expenses: List["RecurringExpense"] = Relationship(back_populates="user")
    # Invoices where this user is the one paying
    invoices_to_pay: List["Invoice"] = Relationship(back_populates="to_user", sa_relationship_kwargs=dict(foreign_keys="[Invoice.to_user_id]"))
    # Invoices where this user is the one being paid
    invoices_to_receive: List["Invoice"] = Relationship(back_populates="from_user", sa_relationship_kwargs=dict(foreign_keys="[Invoice.from_user_id]"))


class Chat(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    created_at: datetime.datetime = Field(default_factory=datetime.datetime.utcnow)
    messages: List["Message"] = Relationship(back_populates="chat")

class Message(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    chat_id: int = Field(foreign_key="chat.id")
    user_id: int = Field(foreign_key="user.id")
    message: str
    response: str
    created_at: datetime.datetime = Field(default_factory=datetime.datetime.utcnow)

    chat: Chat = Relationship(back_populates="messages")
    user: "User" = Relationship(back_populates="messages")

class MessageCreate(BaseModel):
    chat_id: int
    user_id: int
    message: str
    response: str

# --- FINANCE MODULE MODELS ---

class Category(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(index=True, unique=True)
    transactions: List["Transaction"] = Relationship(back_populates="category")

class Transaction(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="user.id")
    account_name: Optional[str] = Field(default=None)
    date: date
    vendor_name: str
    amount: float
    category_id: Optional[int] = Field(foreign_key="category.id")
    is_recurring: bool = Field(default=False)
    recurring_expense_id: Optional[int] = Field(default=None, foreign_key="recurringexpense.id")
    
    owner: "User" = Relationship(back_populates="transactions")
    category: Optional[Category] = Relationship(back_populates="transactions")
    recurring_expense: Optional["RecurringExpense"] = Relationship(back_populates="generated_transactions")
    attributions: List["ExpenseAttribution"] = Relationship(back_populates="original_transaction")


class Budget(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="user.id")
    category_id: int = Field(foreign_key="category.id")
    amount_allocated: float
    start_date: date
    end_date: date

    user: "User" = Relationship(back_populates="budgets")
    category: "Category" = Relationship()

class ExpenseAttributionStatus(str, Enum):
    PENDING = "Pending"
    APPROVED = "Approved"
    REJECTED = "Rejected"

class ExpenseAttribution(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    original_transaction_id: int = Field(foreign_key="transaction.id")
    attributing_user_id: int = Field(foreign_key="user.id")
    attributed_to_user_id: int = Field(foreign_key="user.id")
    amount: float
    status: ExpenseAttributionStatus = Field(default=ExpenseAttributionStatus.PENDING)
    invoice_id: Optional[int] = Field(default=None, foreign_key="invoice.id")

    original_transaction: "Transaction" = Relationship(back_populates="attributions")
    attributing_user: "User" = Relationship(sa_relationship_kwargs=dict(foreign_keys="[ExpenseAttribution.attributing_user_id]"))
    attributed_to_user: "User" = Relationship(sa_relationship_kwargs=dict(foreign_keys="[ExpenseAttribution.attributed_to_user_id]"))
    invoice: Optional["Invoice"] = Relationship(back_populates="attributed_expenses")

class InvoiceStatus(str, Enum):
    UNPAID = "Unpaid"
    PAID = "Paid"

class Invoice(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    from_user_id: int = Field(foreign_key="user.id")
    to_user_id: int = Field(foreign_key="user.id")
    total_amount: float
    due_date: date
    status: InvoiceStatus = Field(default=InvoiceStatus.UNPAID)

    from_user: "User" = Relationship(back_populates="invoices_to_receive", sa_relationship_kwargs=dict(foreign_keys="[Invoice.from_user_id]"))
    to_user: "User" = Relationship(back_populates="invoices_to_pay", sa_relationship_kwargs=dict(foreign_keys="[Invoice.to_user_id]"))
    attributed_expenses: List["ExpenseAttribution"] = Relationship(back_populates="invoice")

class RecurringExpenseFrequency(str, Enum):
    WEEKLY = "Weekly"
    MONTHLY = "Monthly"
    YEARLY = "Yearly"

class RecurringExpense(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="user.id")
    vendor_name: str
    amount: float
    category_id: int = Field(foreign_key="category.id")
    frequency: RecurringExpenseFrequency
    next_due_date: date

    user: "User" = Relationship(back_populates="recurring_expenses")
    category: "Category" = Relationship()
    generated_transactions: List["Transaction"] = Relationship(back_populates="recurring_expense")


class Asset(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str
    value: float
    user_id: int = Field(foreign_key="user.id")

    owner: "User" = Relationship(back_populates="assets")

# --- OTHER APPLICATION MODELS ---

class CalendarEvent(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    title: str
    start_time: datetime.datetime
    end_time: datetime.datetime
    user_id: int = Field(foreign_key="user.id")

    owner: Optional["User"] = Relationship()

class Task(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    title: str
    is_completed: bool = Field(default=False)
    user_id: int = Field(foreign_key="user.id")

    owner: Optional["User"] = Relationship()

class Email(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    subject: str
    sender: str
    recipients: str
    body: str
    timestamp: datetime.datetime = Field(default_factory=datetime.datetime.utcnow)
    user_id: int = Field(foreign_key="user.id")

    owner: Optional["User"] = Relationship()

class Document(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    title: str
    content: str
    user_id: int = Field(foreign_key="user.id")

    owner: Optional["User"] = Relationship()

class CodeFile(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    filename: str
    content: str
    language: str
    user_id: int = Field(foreign_key="user.id")

    owner: Optional["User"] = Relationship()
