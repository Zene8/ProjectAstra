from pydantic import BaseModel
from typing import Optional, List

class ApplicationContext(BaseModel):
    appName: str
    activeItemId: Optional[str] = None
    activeItemContent: Optional[str] = None
    openItems: Optional[List[dict]] = None

class ChatMessageRequest(BaseModel):
    user_id: int
    message: str
    chat_history: list = []
    context: Optional[List[ApplicationContext]] = None

from typing import Optional, List, Dict # Ensure Dict is imported

class SuggestedAction(BaseModel):
    type: str # e.g., "create_calendar_event", "send_email", "create_task"
    description: str # e.g., "Create a new meeting in your calendar"
    payload: Optional[Dict] = None # Data needed to perform the action (e.g., {"title": "Meeting", "date": "today"})

class ChatMessageResponse(BaseModel):
    final_answer: str
    thinking: str
    session_id: str
    suggested_actions: Optional[List[SuggestedAction]] = None # New field
