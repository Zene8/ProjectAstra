from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import os
import sys
sys.path.append(os.path.dirname(os.path.abspath(__file__))) # Add current directory to path for imports
from ncc_service import run_inference_on_ncc

app = FastAPI(
    title="AI Chatbot Service",
    description="Service for offloading LLM inference to NCC.",
    version="1.0.0"
)

class ChatMessageRequest(BaseModel):
    user_id: int
    message: str
    chat_history: list = []

class ChatMessageResponse(BaseModel):
    final_answer: str
    thinking: str
    session_id: str

@app.post("/ai-chat/message", response_model=ChatMessageResponse)
async def send_message_to_ai(request: ChatMessageRequest):
    try:
        # Call the NCC service to run inference
        # The ncc_service.py will handle the actual interaction with the NCC
        final_answer, session_id = await run_inference_on_ncc(request.message, request.chat_history)
        
        # For now, a dummy thinking process. This would ideally come from the LLM.
        thinking_process = "The AI processed the request and generated a response via NCC."

        return ChatMessageResponse(
            final_answer=final_answer,
            thinking=thinking_process,
            session_id=session_id
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get response from AI: {e}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001) # Use a different port than main backend
