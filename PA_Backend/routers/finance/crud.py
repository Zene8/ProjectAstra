from sqlalchemy.orm import Session
from . import models, schemas, security
import pandas as pd
from datetime import datetime

def get_user_by_username(db: Session, username: str):
    return db.query(models.User).filter(models.User.username == username).first()

def create_user(db: Session, user: schemas.UserCreate):
    hashed_password = security.get_password_hash(user.password)
    db_user = models.User(username=user.username, hashed_password=hashed_password)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def create_transaction(db: Session, transaction: schemas.TransactionCreate, user_id: int):
    db_transaction = models.Transaction(**transaction.dict(), owner_id=user_id)
    db.add(db_transaction)
    db.commit()
    db.refresh(db_transaction)
    return db_transaction

def get_transactions(db: Session, user_id: int, skip: int = 0, limit: int = 100):
    return db.exec(select(models.Transaction).where(models.Transaction.user_id == user_id).offset(skip).limit(limit)).all()

def create_transactions_from_csv(db: Session, user_id: int, file):
    df = pd.read_csv(file)
    transactions = []
    for index, row in df.iterrows():
        transaction_data = schemas.TransactionCreate(
            date=datetime.strptime(row['Date'], '%Y-%m-%d').date(),
            description=row['Description'],
            amount=row['Amount'],
            category_id=1  # Default category for now
        )
        db_transaction = models.Transaction(**transaction_data.dict(), owner_id=user_id)
        db.add(db_transaction)
        transactions.append(db_transaction)
    db.commit()
    for transaction in transactions:
        db.refresh(transaction)
    return transactions
