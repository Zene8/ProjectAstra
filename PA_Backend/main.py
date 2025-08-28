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
from typing import Annotated, Optional, List
import logging # Import logging module

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

from database import init_db, get_session
from models import Chat, Message, ApplicationContext # Keep Chat and Message for history persistence
from routers import email, calendar, tasks, documents, coding, brave_search # Keep these for now
from services.local_llm_service import local_llm_service # Import local LLM service
from services.gcp_llm_service import gcp_llm_service # Import GCP LLM service

# --- Environment Variables for Microservice URLs ---
AUTH_SERVICE_URL = os.getenv("AUTH_SERVICE_URL", "http://localhost:8080")
FINANCE_SERVICE_URL = os.getenv("FINANCE_SERVICE_URL", "http://localhost:8081")
AI_CHATBOT_SERVICE_URL = os.getenv("AI_CHATBOT_SERVICE_URL", "http://localhost:8001")
GCP_LLM_CLOUD_RUN_URL = os.getenv("GCP_LLM_CLOUD_RUN_URL") # New environment variable for GCP LLM

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
            logger.warning("User ID is None after JWT decoding.")
            raise credentials_exception
        logger.info(f"User {user_id} authenticated successfully.")
        return user_id
    except JWTError as e:
        logger.error(f"JWT decoding error: {e}")
        raise credentials_exception

# --- Static Files Mounting ---
app.mount("/static", StaticFiles(directory="static"), name="static")

@app.get("/test", summary="Serve Static Test Page")
async def serve_test_page():
    file_path = os.path.join("static", "index.html")
    if os.path.exists(file_path):
        logger.info(f"Serving static test page: {file_path}")
        return FileResponse(file_path, media_type="text/html")
    else:
        logger.error(f"Test HTML page not found at: {file_path}")
        raise HTTPException(status_code=404, detail="Test HTML page not found.")

# --- Environment Detection ---
def get_current_environment():
    if os.getenv("GCP_PROJECT"):
        logger.info("Detected environment: GCP")
        return "gcp"
    elif os.getenv("LOCAL_DEV_ENV") == "true":
        logger.info("Detected environment: Local Development")
        return "local"
    # Add other environment checks as needed (e.g., for NCC if it's a direct deployment)
    logger.info("Detected environment: Unknown (defaulting to unknown)")
    return "unknown"

# --- Event Handlers ---
@app.on_event("startup")
async def on_startup():
    logger.info("Application startup event triggered.")
    await init_db()
    logger.info("Database initialized.")
    # Load local LLM model on startup if in a local environment
    if get_current_environment() == "local":
        local_llm_model_path = os.getenv("LOCAL_LLM_MODEL_PATH")
        local_llm_n_gpu_layers = int(os.getenv("LOCAL_LLM_N_GPU_LAYERS", "0")) # Default to 0 for CPU
        if local_llm_model_path:
            logger.info(f"Attempting to load local LLM model from: {local_llm_model_path} with {local_llm_n_gpu_layers} GPU layers.")
            local_llm_service.load_model(model_path=local_llm_model_path, n_gpu_layers=local_llm_n_gpu_layers)
        else:
            logger.warning("LOCAL_LLM_MODEL_PATH environment variable not set. Local LLM will not be loaded.")
    
    # Initialize GCP LLM service if Cloud Run URL is provided
    if GCP_LLM_CLOUD_RUN_URL:
        logger.info(f"GCP_LLM_CLOUD_RUN_URL is set. Initializing GCP LLM service with URL: {GCP_LLM_CLOUD_RUN_URL}")
        gcp_llm_service.initialize(cloud_run_url=GCP_LLM_CLOUD_RUN_URL)
    else:
        logger.info("GCP_LLM_CLOUD_RUN_URL not set. GCP LLM service will not be initialized.")

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
    context: Optional[List[ApplicationContext]] = None
    ai_backend: Optional[str] = None # Add field for AI backend selection

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

    current_env = get_current_environment()
    selected_backend = user_input.ai_backend

    final_answer = ""
    thinking_process = ""
    session_id = "default_session" # Placeholder

    try:
        if selected_backend == "backendLocal":
            if current_env != "local":
                raise HTTPException(status_code=400, detail=f"Backend Local AI can only be used in 'local' environment. Current environment: '{current_env}'.")
            # Use local LLM service
            final_answer = local_llm_service.generate_response(
                prompt=user_input.message,
                chat_history=chat_history,
                context=[c.dict() for c in user_input.context] if user_input.context else []
            )
            thinking_process = "Generated by local LLM."
        elif selected_backend == "gcp":
            if current_env != "gcp":
                raise HTTPException(status_code=400, detail=f"GCP AI can only be used in 'gcp' environment. Current environment: '{current_env}'.")
            if not gcp_llm_service._cloud_run_url:
                raise HTTPException(status_code=500, detail="GCP LLM service not configured. GCP_LLM_CLOUD_RUN_URL environment variable is missing.")
            final_answer = await gcp_llm_service.generate_response(
                prompt=user_input.message,
                chat_history=chat_history,
                context=[c.dict() for c in user_input.context] if user_input.context else []
            )
            thinking_process = "Generated by GCP LLM."
        elif selected_backend == "ncc":
            if current_env != "ncc" and AI_CHATBOT_SERVICE_URL == "http://localhost:8001": # Assuming localhost:8001 is for local dev of NCC service
                raise HTTPException(status_code=400, detail=f"NCC AI can only be used in 'ncc' environment or with a configured AI_CHATBOT_SERVICE_URL. Current environment: '{current_env}'.")
            async with httpx.AsyncClient() as client:
                ai_response = await client.post(
                    f"{AI_CHATBOT_SERVICE_URL}/ai-chat/message",
                    json={
                        "user_id": user_id,
                        "message": user_input.message,
                        "chat_history": chat_history,
                        "context": [c.dict() for c in user_input.context] if user_input.context else []
                    }
                )
                ai_response.raise_for_status()
                ai_data = ai_response.json()
                final_answer = ai_data.get("final_answer")
                thinking_process = ai_data.get("thinking")
                session_id = ai_data.get("session_id")
        elif selected_backend is None:
            # Default routing if no backend is explicitly selected by the frontend
            if current_env == "local":
                # Fallback to local LLM if running locally and no specific backend chosen
                final_answer = local_llm_service.generate_response(
                    prompt=user_input.message,
                    chat_history=chat_history,
                    context=[c.dict() for c in user_input.context] if user_input.context else []
                )
                thinking_process = "Generated by default local LLM."
            elif current_env == "gcp":
                if not gcp_llm_service._cloud_run_url:
                    raise HTTPException(status_code=500, detail="GCP LLM service not configured for default routing. GCP_LLM_CLOUD_RUN_URL environment variable is missing.")
                final_answer = await gcp_llm_service.generate_response(
                    prompt=user_input.message,
                    chat_history=chat_history,
                    context=[c.dict() for c in user_input.context] if user_input.context else []
                )
                thinking_process = "Generated by default GCP LLM."
            elif current_env == "ncc":
                # Fallback to NCC if running on NCC and no specific backend chosen
                async with httpx.AsyncClient() as client:
                    ai_response = await client.post(
                        f"{AI_CHATBOT_SERVICE_URL}/ai-chat/message",
                        json={
                            "user_id": user_id,
                            "message": user_input.message,
                            "chat_history": chat_history,
                            "context": [c.dict() for c in user_input.context] if user_input.context else []
                        }
                    )
                    ai_response.raise_for_status()
                    ai_data = ai_response.json()
                    final_answer = ai_data.get("final_answer")
                    thinking_process = ai_data.get("thinking")
                    session_id = ai_data.get("session_id")
            else:
                raise HTTPException(status_code=501, detail=f"No default AI backend configured for environment '{current_env}'. Please select an AI backend.")
        else:
            raise HTTPException(status_code=400, detail=f"AI backend '{selected_backend}' is not a valid selection or not supported in current environment '{current_env}'.")

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

        return AIChatResponse(final_answer=final_answer, thinking=thinking_process, session_id=session_id)

    except httpx.RequestError as exc:
        raise HTTPException(status_code=500, detail=f"Communication error with AI service: {exc}")
    except httpx.HTTPStatusError as exc:
        raise HTTPException(status_code=exc.response.status_code, detail=f"AI service returned an error: {exc.response.text}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An unexpected error occurred during AI processing: {e}")

# --- Routers for other existing Python services (will be updated to use get_current_user_id) ---
app.include_router(email.router, prefix="/api", tags=["email"])
app.include_router(calendar.router, prefix="/api", tags=["calendar"])
app.include_router(tasks.router, prefix="/api", tags=["tasks"])
app.include_router(documents.router, prefix="/api", tags=["documents"])
app.include_router(coding.router, prefix="/api", tags=["coding"])
app.include_router(brave_search.router, prefix="/api", tags=["brave_search"])
app.include_router(outlook.router, prefix="/api", tags=["outlook"]) # New Outlook router
app.include_router(todo.router, prefix="/api", tags=["todo"]) # New To Do router

# --- Main Block for Running with Uvicorn (Optional) ---
if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=5000, reload=True)