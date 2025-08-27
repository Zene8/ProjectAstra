from fastapi import FastAPI, HTTPException
from typing import Optional, List
from langchain_core.messages import BaseMessage, HumanMessage, AIMessage

from config import AI_MODELS, DEFAULT_AI_MODEL
from agent import create_agent_workflow, AgentState
from routers.finance import finance, plaid, reports, ai

app = FastAPI()

# Initialize the agent workflow once
# This will use the default model, but can be extended to dynamically load workflows
agent_workflow = create_agent_workflow(DEFAULT_AI_MODEL)

app.include_router(finance.router, prefix="/api")
app.include_router(plaid.router, prefix="/api")
app.include_router(reports.router, prefix="/api")
app.include_router(ai.router, prefix="/api")

@app.get("/")
def read_root():
    return {"message": "Welcome to the Astra AI Backend!"}

@app.post("/chat")
async def chat(message: str, model_name: Optional[str] = None, chat_history: Optional[List[dict]] = None):
    if chat_history is None:
        chat_history = []

    # Convert chat_history to BaseMessage objects
    converted_chat_history = []
    for entry in chat_history:
        if entry.get("role") == "user":
            converted_chat_history.append(HumanMessage(content=entry.get("content")))
        elif entry.get("role") == "ai":
            converted_chat_history.append(AIMessage(content=entry.get("content")))

    # Prepare the initial state for the agent
    initial_state = AgentState(
        input=message,
        chat_history=converted_chat_history,
        agent_outcome=None,
        intermediate_steps=[]
    )

    try:
        # Run the agent workflow
        # The agent will handle model selection (local/NCC) and tool usage
        final_state = await agent_workflow.ainvoke(initial_state)
        
        # Extract the final response from the agent's output
        # This might need adjustment based on how your agent returns the final answer
        response_content = "No response from agent." # Default message
        if final_state and final_state.get("agent_outcome"):
            if isinstance(final_state["agent_outcome"], AgentFinish):
                response_content = final_state["agent_outcome"].return_values["output"]
            else:
                # If the agent didn't finish, it might have called a tool or is in an intermediate state
                # You might want to log this or handle it differently
                response_content = f"Agent is still processing or called a tool. Last action: {final_state['agent_outcome']}"

        return {"response": response_content}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Agent workflow failed: {e}")
