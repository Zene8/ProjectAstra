from fastapi import FastAPI, HTTPException
import os
import sys
sys.path.append(os.path.dirname(os.path.abspath(__file__))) # Add current directory to path for imports
from ncc_service import run_inference_on_ncc
from models import ChatMessageRequest, ChatMessageResponse, SuggestedAction # Import models

app = FastAPI(
    title="AI Chatbot Service",
    description="Service for offloading LLM inference to NCC.",
    version="1.0.0"
)

@app.post("/ai-chat/message", response_model=ChatMessageResponse)
async def send_message_to_ai(request: ChatMessageRequest):
    try:
        # Call the NCC service to run inference
        # The ncc_service.py will handle the actual interaction with the NCC
        final_answer, session_id = await run_inference_on_ncc(request.message, request.chat_history, request.context)
        
        # For now, a dummy thinking process. This would ideally come from the LLM.
        thinking_process = "The AI processed the request and generated a response via NCC."

        # Placeholder for suggested actions
        suggested_actions = []
        if "meeting" in request.message.lower() and any(c.appName == "Calendar" for c in request.context if c.appName):
            suggested_actions.append(
                SuggestedAction(
                    type="create_calendar_event",
                    description="Create a new meeting in your calendar",
                    payload={"title": "New Meeting", "notes": request.message}
                )
            )
        elif "email" in request.message.lower():
             suggested_actions.append(
                SuggestedAction(
                    type="send_email",
                    description="Compose a new email",
                    payload={"subject": "Regarding your message", "body": request.message}
                )
            )

        return ChatMessageResponse(
            final_answer=final_answer,
            thinking=thinking_process,
            session_id=session_id,
            suggested_actions=suggested_actions # Include suggested actions
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get response from AI: {e}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001) # Use a different port than main backend
