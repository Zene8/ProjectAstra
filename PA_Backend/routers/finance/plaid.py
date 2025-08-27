from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session
import plaid
from plaid.api import plaid_api
from plaid.model.link_token_create_request import LinkTokenCreateRequest
from plaid.model.link_token_create_request_user import LinkTokenCreateRequestUser
from plaid.model.products import Products
from plaid.model.country_code import CountryCode
from plaid.model.item_public_token_exchange_request import ItemPublicTokenExchangeRequest
from plaid.model.transactions_sync_request import TransactionsSyncRequest
import os

from .. import models, schemas, crud
from ..database import get_session
from .finance import get_current_user

router = APIRouter(
    prefix="/finance/plaid",
    tags=["plaid"],
)

# Plaid configuration
PLAID_CLIENT_ID = os.getenv("PLAID_CLIENT_ID")
PLAID_SECRET = os.getenv("PLAID_SECRET")
PLAID_ENV = os.getenv("PLAID_ENV", "sandbox")

if PLAID_ENV == 'sandbox':
    host = plaid.Environment.Sandbox
elif PLAID_ENV == 'development':
    host = plaid.Environment.Development
else:
    host = plaid.Environment.Production

configuration = plaid.Configuration(
    host=host,
    api_key={
        'clientId': PLAID_CLIENT_ID,
        'secret': PLAID_SECRET,
    }
)

api_client = plaid.ApiClient(configuration)
client = plaid_api.PlaidApi(api_client)

@router.post("/create_link_token")
def create_link_token(current_user: models.User = Depends(get_current_user)):
    try:
        request = LinkTokenCreateRequest(
            user=LinkTokenCreateRequestUser(client_user_id=str(current_user.id)),
            client_name="Project Astra",
            products=[Products('transactions')],
            country_codes=[CountryCode('US')],
            language='en',
        )
        response = client.link_token_create(request)
        return response.to_dict()
    except plaid.ApiException as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e.body))

@router.post("/exchange_public_token")
def exchange_public_token(
    public_token_request: schemas.PlaidPublicTokenExchangeRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_session)
):
    try:
        exchange_request = ItemPublicTokenExchangeRequest(public_token=public_token_request.public_token)
        exchange_response = client.item_public_token_exchange(exchange_request)
        access_token = exchange_response['access_token']
        item_id = exchange_response['item_id']
        crud.set_plaid_access_token(db, user_id=current_user.id, plaid_access_token=access_token, plaid_item_id=item_id)
        return {"status": "success"}
    except plaid.ApiException as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e.body))

@router.post("/sync_transactions")
def sync_transactions(current_user: models.User = Depends(get_current_user), db: Session = Depends(get_session)):
    if not current_user.plaid_access_token:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Plaid not linked")

    try:
        request = TransactionsSyncRequest(access_token=current_user.plaid_access_token)
        response = client.transactions_sync(request)
        transactions = response['added']
        
        for t in transactions:
            transaction_data = schemas.TransactionCreate(
                date=t['date'],
                vendor_name=t['merchant_name'] or t['name'],
                amount=t['amount'],
                account_name=t.get('account_details', {}).get('name'),
            )
            crud.create_transaction(db, transaction=transaction_data, user_id=current_user.id)

        return {"transactions_added": len(transactions)}
    except plaid.ApiException as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e.body))
