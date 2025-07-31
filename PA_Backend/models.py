from typing import Optional, List
from pydantic import BaseModel
from sqlmodel import Field, SQLModel, Relationship
import datetime
from datetime import date

class User(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    username: Optional[str] = Field(index=True, unique=True, default=None)
    email: str = Field(index=True, unique=True)
    hashed_password: Optional[str] = Field(default=None) # Added from finance_manager
    google_credentials: Optional[str] = Field(default=None)
    created_at: datetime.datetime = Field(default_factory=datetime.datetime.utcnow)

    messages: List["Message"] = Relationship(back_populates="user")
    transactions: List["Transaction"] = Relationship(back_populates="owner") # Added from finance_manager
    assets: List["Asset"] = Relationship(back_populates="owner") # Added from finance_manager

class Chat(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    created_at: datetime.datetime = Field(default_factory=datetime.datetime.utcnow)
    messages: List["Message"] = Relationship(back_populates="chat")

class Message(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    chat_id: int = Field(foreign_key="chat.id")
    user_id: int = Field(foreign_key="users.id") # Changed to users.id
    message: str
    response: str
    created_at: datetime.datetime = Field(default_factory=datetime.datetime.utcnow)

    chat: Chat = Relationship(back_populates="messages")
    user: User = Relationship(back_populates="messages")

class MessageCreate(BaseModel):
    chat_id: int
    user_id: int
    message: str
    response: str

# Finance Manager Models (converted to SQLModel)
class Category(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(index=True, unique=True)

    transactions: List["Transaction"] = Relationship(back_populates="category")

class Transaction(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    date: date
    description: str
    amount: float
    category_id: int = Field(foreign_key="category.id")
    user_id: int = Field(foreign_key="users.id")

    category: Optional[Category] = Relationship(back_populates="transactions")
    owner: Optional[User] = Relationship(back_populates="transactions")

class Asset(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str
    value: float
    user_id: int = Field(foreign_key="users.id")

    owner: Optional[User] = Relationship(back_populates="assets")