from pydantic import BaseModel
from typing import List, Optional
from datetime import date

class TransactionBase(BaseModel):
    date: date
    description: str
    amount: float
    category_id: int

class TransactionCreate(TransactionBase):
    pass

class Transaction(TransactionBase):
    id: int
    owner_id: int

    class Config:
        orm_mode = True

class CategoryBase(BaseModel):
    name: str

class CategoryCreate(CategoryBase):
    pass

class Category(CategoryBase):
    id: int

    class Config:
        orm_mode = True

class AssetBase(BaseModel):
    name: str
    value: float

class AssetCreate(AssetBase):
    pass

class Asset(AssetBase):
    id: int
    owner_id: int

    class Config:
        orm_mode = True

class UserBase(BaseModel):
    username: str

class UserCreate(UserBase):
    password: str

class User(UserBase):
    id: int
    transactions: List[Transaction] = []
    assets: List[Asset] = []

    class Config:
        orm_mode = True

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    username: Optional[str] = None
