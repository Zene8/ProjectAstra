import uvicorn
from fastapi import FastAPI, HTTPException, Depends, Request, Response, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse, JSONResponse
from pydantic import BaseModel
import os
from sqlmodel import select
from sqlalchemy.ext.asyncio import AsyncSession
import httpx
from jose import jwt, JWTError
from fastapi.security import OAuth2PasswordBearer
from typing import Annotated

from database import init_db, get_session
from models import Chat, Message # Keep Chat and Message for history persistence
from routers import email, calendar, tasks, documents, coding, brave_search # Keep these for now

# --- Environment Variables for Microservice URLs ---
AUTH_SERVICE_URL = os.getenv("AUTH_SERVICE_URL", "http://localhost:8080")
FINANCE_SERVICE_URL = os.getenv("FINANCE_SERVICE_URL", "http://localhost:8081")
AI_CHATBOT_SERVICE_URL = os.getenv("AI_CHATBOT_SERVICE_URL", "http://localhost:8001")

# --- FastAPI App Initialization ---
app = FastAPI(
    title="AI Agent Orchestration Server (API Gateway)",
    description="A FastAPI server acting as an API Gateway for microservices.",
    version="2.0.0"
)

# --- CORS Middleware ---
origins = ["*"]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- JWT Authentication Dependency ---
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")

async def get_current_user_id(token: Annotated[str, Depends(oauth2_scheme)]) -> int:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        # Assuming the token is issued by the Auth service and contains user_id in 'sub' claim
        payload = jwt.decode(token, os.getenv("JWT_SECRET_KEY", "super-secret-jwt-key"), algorithms=["HS256"])
        user_id: int = int(payload.get("sub"))
        if user_id is None:
            raise credentials_exception
        return user_id
    except JWTError:
        raise credentials_exception

# --- Static Files Mounting ---
app.mount("/static", StaticFiles(directory="static"), name="static")

@app.get("/test", summary="Serve Static Test Page")
async def serve_test_page():
    file_path = os.path.join("static", "index.html")
    if os.path.exists(file_path):
        return FileResponse(file_path, media_type="text/html")
    else:
        raise HTTPException(status_code=404, detail="Test HTML page not found.")

# --- Event Handlers ---
@app.on_event("startup")
async def on_startup():
    await init_db()

# --- Root Endpoint ---
@app.get("/", summary="Root Endpoint")
async def read_root():
    return {"message": "Welcome to the AI Agent Orchestration Server (API Gateway)!"}

# --- Proxy Endpoints for Auth Service ---
@app.api_route("/api/auth/{path:path}", methods=["GET", "POST", "PUT", "DELETE"])
async def proxy_auth_service(path: str, request: Request):
    async with httpx.AsyncClient() as client:
        url = f"{AUTH_SERVICE_URL}/auth/{path}"
        headers = {k: v for k, v in request.headers.items() if k.lower() not in ["host", "authorization"]}
        if request.headers.get("authorization"):
            headers["Authorization"] = request.headers["authorization"]
        
        try:
            response = await client.request(
                method=request.method,
                url=url,
                headers=headers,
                content=await request.body(),
                params=request.query_params
            )
            return JSONResponse(content=response.json(), status_code=response.status_code)
        except httpx.RequestError as exc:
            raise HTTPException(status_code=500, detail=f"Auth service communication error: {exc}")
        except httpx.HTTPStatusError as exc:
            raise HTTPException(status_code=exc.response.status_code, detail=exc.response.text)

# --- Proxy Endpoints for Finance Service ---
@app.api_route("/api/finance/{path:path}", methods=["GET", "POST", "PUT", "DELETE"])
async def proxy_finance_service(path: str, request: Request, user_id: Annotated[int, Depends(get_current_user_id)]):
    async with httpx.AsyncClient() as client:
        url = f"{FINANCE_SERVICE_URL}/finance/{path}"
        headers = {k: v for k, v in request.headers.items() if k.lower() not in ["host"]}
        # Pass user_id to finance service, potentially in a custom header or as part of the body if needed
        headers["X-User-ID"] = str(user_id) # Example: pass user_id in a custom header
        
        try:
            response = await client.request(
                method=request.method,
                url=url,
                headers=headers,
                content=await request.body(),
                params=request.query_params
            )
            return JSONResponse(content=response.json(), status_code=response.status_code)
        except httpx.RequestError as exc:
            raise HTTPException(status_code=500, detail=f"Finance service communication error: {exc}")
        except httpx.HTTPStatusError as exc:
            raise HTTPException(status_code=exc.response.status_code, detail=exc.response.text)

# --- AI Chatbot Endpoint ---
class UserMessageInput(BaseModel):
    message: str

class AIChatResponse(BaseModel):
    final_answer: str
    thinking: str
    session_id: str

@app.post("/api/chat", response_model=AIChatResponse)
async def chat_with_ai(
    user_input: UserMessageInput,
    user_id: Annotated[int, Depends(get_current_user_id)],
    session: AsyncSession = Depends(get_session)
):
    # 1. Retrieve chat history for the user
    # For simplicity, let's assume one chat per user for now, or create a new one if none exists
    chat = (await session.execute(select(Chat).where(Chat.user_id == user_id))).scalars().first()
    if not chat:
        chat = Chat(user_id=user_id) # Assuming Chat model has user_id
        session.add(chat)
        await session.commit()
        await session.refresh(chat)

    messages = (await session.execute(select(Message).where(Message.chat_id == chat.id).order_by(Message.created_at))).scalars().all()
    
    chat_history = [{"message": msg.message, "response": msg.response} for msg in messages]

    # 2. Call the AI Chatbot Service
    async with httpx.AsyncClient() as client:
        try:
            ai_response = await client.post(
                f"{AI_CHATBOT_SERVICE_URL}/ai-chat/message",
                json={
                    "user_id": user_id,
                    "message": user_input.message,
                    "chat_history": chat_history
                }
            )
            ai_response.raise_for_status()
            ai_data = ai_response.json()
            final_answer = ai_data.get("final_answer")
            thinking = ai_data.get("thinking")
            session_id = ai_data.get("session_id")

            # 3. Persist the new user message and AI response
            new_message = Message(
                chat_id=chat.id,
                user_id=user_id,
                message=user_input.message,
                response=final_answer
            )
            session.add(new_message)
            await session.commit()
            await session.refresh(new_message)

            return AIChatResponse(final_answer=final_answer, thinking=thinking, session_id=session_id)

        except httpx.RequestError as exc:
            raise HTTPException(status_code=500, detail=f"AI Chatbot service communication error: {exc}")
        except httpx.HTTPStatusError as exc:
            raise HTTPException(status_code=exc.response.status_code, detail=exc.response.text)

# --- Routers for other existing Python services (will be updated to use get_current_user_id) ---
app.include_router(email.router, prefix="/api", tags=["email"])
app.include_router(calendar.router, prefix="/api", tags=["calendar"])
app.include_router(tasks.router, prefix="/api", tags=["tasks"])
app.include_router(documents.router, prefix="/api", tags=["documents"])
app.include_router(coding.router, prefix="/api", tags=["coding"])
app.include_router(brave_search.router, prefix="/api", tags=["brave_search"])

# --- Main Block for Running with Uvicorn (Optional) ---
if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=5000, reload=True)
