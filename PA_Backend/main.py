import uvicorn
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from pydantic import BaseModel
import os
from sqlmodel import select
from sqlalchemy.ext.asyncio import AsyncSession

from database import init_db, get_session
from models import User
from ncc_service import run_inference_on_ncc
from routers import email, calendar, tasks, documents, coding, auth, finance, brave_search

# --- Pydantic Models ---
class UserInput(BaseModel):
    message: str


class AgentResponse(BaseModel):
    response: str
    session_id: str

# --- FastAPI App Initialization ---
app = FastAPI(
    title="AI Agent Orchestration Server",
    description="A FastAPI server to manage user interactions and offload LLM inference to the NCC.",
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

# --- Routers ---
app.include_router(auth.router, prefix="/api", tags=["auth"])
app.include_router(email.router, prefix="/api", tags=["email"])
app.include_router(calendar.router, prefix="/api", tags=["calendar"])
app.include_router(tasks.router, prefix="/api", tags=["tasks"])
app.include_router(documents.router, prefix="/api", tags=["documents"])
app.include_router(coding.router, prefix="/api", tags=["coding"])
app.include_router(finance.router, prefix="/api/finance", tags=["finance"])

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

# --- API Endpoints ---
@app.get("/", summary="Root Endpoint")
async def read_root():
    return {"message": "Welcome to the AI Agent Orchestration Server!"}



# --- Main Block for Running with Uvicorn (Optional) ---
if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=5000, reload=True)
