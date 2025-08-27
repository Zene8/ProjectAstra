from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select, func
from sqlalchemy import and_
from datetime import date

from .. import models, schemas
from ..database import get_session
from .finance import get_current_user
from .plaid import client as plaid_client

router = APIRouter(
    prefix="/finance/reports",
    tags=["reports"],
)

@router.get("/net_worth")
def get_net_worth(current_user: models.User = Depends(get_current_user), db: Session = Depends(get_session)):
    if not current_user.plaid_access_token:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Plaid not linked")

    try:
        request = plaid_api.AccountsBalanceGetRequest(access_token=current_user.plaid_access_token)
        response = plaid_client.accounts_balance_get(request)
        accounts = response['accounts']
        
        net_worth = 0
        for account in accounts:
            if account['type'] == 'depository' or account['type'] == 'investment':
                net_worth += account['balances']['current']
            elif account['type'] == 'loan' or account['type'] == 'credit':
                net_worth -= account['balances']['current']

        return {"net_worth": net_worth}
    except plaid.ApiException as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e.body))

@router.get("/spending_breakdown")
def get_spending_breakdown(
    start_date: date,
    end_date: date,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_session)
):
    spending_by_category = db.exec(
        select(models.Category.name, func.sum(models.Transaction.amount))
        .join(models.Transaction)
        .where(and_(
            models.Transaction.user_id == current_user.id,
            models.Transaction.date >= start_date,
            models.Transaction.date <= end_date,
            models.Transaction.amount > 0
        ))
        .group_by(models.Category.name)
    ).all()

    return {category: amount for category, amount in spending_by_category}
