from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import httpx
import os
from ..config import BRAVE_SEARCH_API_KEY

router = APIRouter()

class SearchQuery(BaseModel):
    query: str

@router.post("/brave_search")
async def brave_search(search_query: SearchQuery):
    if not BRAVE_SEARCH_API_KEY:
        raise HTTPException(status_code=500, detail="Brave Search API key not configured.")

    headers = {
        "X-Subscription-Token": BRAVE_SEARCH_API_KEY
    }
    params = {
        "q": search_query.query
    }

    async with httpx.AsyncClient() as client:
        try:
            response = await client.get("https://api.search.brave.com/res/v1/web/search", headers=headers, params=params)
            response.raise_for_status()  # Raise an exception for 4xx or 5xx status codes
            return response.json()
        except httpx.RequestError as exc:
            raise HTTPException(status_code=500, detail=f"An error occurred while requesting Brave Search: {exc}")
        except httpx.HTTPStatusError as exc:
            raise HTTPException(status_code=exc.response.status_code, detail=f"Error from Brave Search API: {exc.response.text}")
