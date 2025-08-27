from typing import TypedDict, Annotated, List, Union
import operator
from langchain_core.agents import AgentAction, AgentFinish
from langchain_core.messages import BaseMessage, HumanMessage
from langchain_core.prompts import ChatPromptTemplate
from langchain_community.llms import Ollama
from langchain_core.tools import tool
from langchain.agents import AgentExecutor, create_react_agent
from langgraph.graph import StateGraph, END
from langchain_core.runnables import Runnable
from langchain_core.language_models import BaseChatModel

from ncc_service import NCCService
from config import AI_MODELS, DEFAULT_AI_MODEL
from agent_tools import (
    brave_search_tool,
    create_calendar_event_tool,
    get_calendar_events_tool,
    create_code_file_tool,
    get_code_files_tool,
    update_code_file_tool,
    delete_code_file_tool,
    create_document_tool,
    get_documents_tool,
    create_email_tool,
    get_emails_tool,
    create_transaction_tool,
    get_transactions_tool,
    create_asset_tool,
    get_assets_tool,
    create_category_tool,
    get_categories_tool,
    create_task_tool,
    get_tasks_tool,
    run_ncc_compute_tool,
    read_project_file_tool,
    write_project_file_tool,
    list_project_directory_tool,
    search_project_files_tool,
    glob_project_files_tool
)
from database import get_session

# Initialize NCCService
ncc_service = NCCService()

# Custom LLM for NCC
class NCCLLM(BaseChatModel):
    model_name: str

    def _generate(self, messages: List[BaseMessage], stop: Optional[List[str]] = None, **kwargs) -> ChatGeneration:
        # Convert messages to a format suitable for your NCC inference script
        prompt = messages[-1].content # Assuming the last message is the user's prompt
        chat_history = []
        for msg in messages[:-1]:
            chat_history.append({"role": msg.type, "content": msg.content})

        response_text, _ = asyncio.run(ncc_service.run_inference_on_ncc(prompt, chat_history))
        return ChatGeneration(message=AIMessage(content=response_text))

    @property
    def _llm_type(self) -> str:
        return "ncc-llm"

# Initialize LLMs
def _get_llm(model_name: str):
    model_config = AI_MODELS.get(model_name)
    if not model_config:
        raise ValueError(f"Model {model_name} not found in configuration.")

    if model_config["type"] == "local":
        # Ollama expects the model name, not a path. The path is for downloading/managing.
        # Assuming Ollama has the model pulled based on its 'name'.
        return Ollama(model=model_config["name"])
    elif model_config["type"] == "ncc":
        return NCCLLM(model_name=model_config["name"])
    else:
        raise ValueError(f"Unknown model type: {model_config["type"]}")

# Define Tools
@tool
async def brave_search(query: str) -> dict:
    """Performs a web search using Brave Search."""
    return await brave_search_tool(query)

@tool
def read_project_file(relative_file_path: str) -> str:
    """Reads the content of a file within the project. Use this to inspect code or configuration files."
    return read_project_file_tool(relative_file_path)

@tool
def write_project_file(relative_file_path: str, content: str) -> None:
    """Writes content to a file within the project. Use this to create new files or modify existing ones."""
    return write_project_file_tool(relative_file_path, content)

@tool
def list_project_directory(relative_path: str = ".") -> List[str]:
    """Lists the names of files and subdirectories directly within a specified directory relative to the project root. Use this to explore the project structure."""
    return list_project_directory_tool(relative_path)

@tool
def search_project_files(pattern: str, relative_path: str = ".", include: Optional[str] = None) -> List[Dict]:
    """Searches for a regular expression pattern within the content of files in a specified directory relative to the project root. Use this to find specific code patterns or text."
    return search_project_files_tool(pattern, relative_path, include)

@tool
def glob_project_files(pattern: str, relative_path: str = ".") -> List[str]:
    """Finds files matching a glob pattern within a specified directory relative to the project root. Use this to locate files by name or pattern."
    return glob_project_files_tool(pattern, relative_path)

@tool
def create_calendar_event(user_id: int, title: str, start_time: str, end_time: str) -> dict:
    """Creates a new calendar event for the user."""
    with get_session() as db:
        return create_calendar_event_tool(user_id, title, start_time, end_time, db).dict()

@tool
def get_calendar_events(user_id: int, skip: int = 0, limit: int = 100) -> List[dict]:
    """Retrieves calendar events for the user."""
    with get_session() as db:
        return [event.dict() for event in get_calendar_events_tool(user_id, db, skip, limit)]

@tool
def create_code_file(user_id: int, filename: str, content: str, language: str) -> dict:
    """Creates a new code file for the user."""
    with get_session() as db:
        return create_code_file_tool(user_id, filename, content, language, db).dict()

@tool
def get_code_files(user_id: int, skip: int = 0, limit: int = 100) -> List[dict]:
    """Retrieves code files for the user."""
    with get_session() as db:
        return [file.dict() for file in get_code_files_tool(user_id, db, skip, limit)]

@tool
def update_code_file(user_id: int, code_file_id: int, filename: Optional[str] = None, content: Optional[str] = None, language: Optional[str] = None) -> dict:
    """Updates an existing code file for the user."""
    with get_session() as db:
        return update_code_file_tool(user_id, code_file_id, db, filename, content, language).dict()

@tool
def delete_code_file(user_id: int, code_file_id: int) -> dict:
    """Deletes a code file for the user."""
    with get_session() as db:
        return delete_code_file_tool(user_id, code_file_id, db)


# Group tools by suite
BRAVE_SEARCH_TOOLS = [brave_search]
CALENDAR_TOOLS = [create_calendar_event, get_calendar_events]
CODING_TOOLS = [create_code_file, get_code_files, update_code_file, delete_code_file, run_ncc_compute, read_project_file, write_project_file, list_project_directory, search_project_files, glob_project_files]
DOCUMENT_TOOLS = [create_document, get_documents]
EMAIL_TOOLS = [create_email, get_emails]
FINANCE_TOOLS = [create_transaction, get_transactions, create_asset, get_assets, create_category, get_categories]
TASK_TOOLS = [create_task, get_tasks]

ALL_TOOLS = (
    BRAVE_SEARCH_TOOLS +
    CALENDAR_TOOLS +
    CODING_TOOLS +
    DOCUMENT_TOOLS +
    EMAIL_TOOLS +
    FINANCE_TOOLS +
    TASK_TOOLS
)

# Define AgentState
class AgentState(TypedDict):
    input: str
    chat_history: List[BaseMessage]
    agent_outcome: Annotated[Union[AgentAction, AgentFinish, None], operator.attrgetter("agent_outcome")]
    intermediate_steps: Annotated[List[tuple[AgentAction, str]], operator.add]
    # db_session: Session # Removed for now, using get_session() directly in tools

# Agent Node
class Agent:
    def __init__(self, model_name: str, tools: List[Runnable]):
        self.llm = _get_llm(model_name)
        self.tools = tools
        self.prompt = ChatPromptTemplate.from_messages([
            ("system", "You are a helpful AI assistant with access to various tools. Use them as needed."),
            ("placeholder", "{chat_history}"),
            ("human", "{input}"),
            ("placeholder", "{agent_scratchpad}"),
        ])
        self.agent_executor = create_react_agent(self.llm, self.tools, self.prompt)

    def __call__(self, state: AgentState):
        agent_outcome = self.agent_executor.invoke(state)
        return {"agent_outcome": agent_outcome}

# Tool Node
class ToolNode:
    def __init__(self, tools: List[Runnable]):
        self.tools_by_name = {tool.name: tool for tool in tools}

    def __call__(self, state: AgentState):
        tool_action = state["agent_outcome"]
        tool_name = tool_action.tool
        tool_input = tool_action.tool_input
        
        if tool_name not in self.tools_by_name:
            raise ValueError(f"Tool {tool_name} not found.")

        tool_result = self.tools_by_name[tool_name].invoke(tool_input)
        return {"intermediate_steps": [(tool_action, str(tool_result))]}

# Routing function
def route_agent(state: AgentState):
    tool_name = state["agent_outcome"].tool
    if tool_name in [tool.name for tool in BRAVE_SEARCH_TOOLS]:
        return "brave_search_agent"
    elif tool_name in [tool.name for tool in CALENDAR_TOOLS]:
        return "calendar_agent"
    elif tool_name in [tool.name for tool in CODING_TOOLS]:
        return "coding_agent"
    elif tool_name in [tool.name for tool in DOCUMENT_TOOLS]:
        return "document_agent"
    elif tool_name in [tool.name for tool in EMAIL_TOOLS]:
        return "email_agent"
    elif tool_name in [tool.name for tool in FINANCE_TOOLS]:
        return "finance_agent"
    elif tool_name in [tool.name for tool in TASK_TOOLS]:
        return "task_agent"
    else:
        return "__end__" # Should not happen if all tools are covered

# Define the graph
def create_agent_workflow(model_name: str):
    workflow = StateGraph(AgentState)

    # Main Agent Node
    workflow.add_node("main_agent", Agent(DEFAULT_AI_MODEL, ALL_TOOLS))
    workflow.add_node("main_tool_node", ToolNode(ALL_TOOLS))

    # Suite-specific Agent Nodes and Tool Nodes
    workflow.add_node("brave_search_agent", Agent("phi-3-mini", BRAVE_SEARCH_TOOLS))
    workflow.add_node("brave_search_tool_node", ToolNode(BRAVE_SEARCH_TOOLS))

    workflow.add_node("calendar_agent", Agent("gemma-2b", CALENDAR_TOOLS))
    workflow.add_node("calendar_tool_node", ToolNode(CALENDAR_TOOLS))

    workflow.add_node("coding_agent", Agent("codegemma-2b", CODING_TOOLS))
    workflow.add_node("coding_tool_node", ToolNode(CODING_TOOLS))

    workflow.add_node("document_agent", Agent("gemma-2b", DOCUMENT_TOOLS))
    workflow.add_node("document_tool_node", ToolNode(DOCUMENT_TOOLS))

    workflow.add_node("email_agent", Agent("gemma-2b", EMAIL_TOOLS))
    workflow.add_node("email_tool_node", ToolNode(EMAIL_TOOLS))

    workflow.add_node("finance_agent", Agent("gemma-2b", FINANCE_TOOLS))
    workflow.add_node("finance_tool_node", ToolNode(FINANCE_TOOLS))

    workflow.add_node("task_agent", Agent("gemma-2b", TASK_TOOLS))
    workflow.add_node("task_tool_node", ToolNode(TASK_TOOLS))

    # Define edges
    workflow.set_entry_point("main_agent")

    # Main agent logic
    workflow.add_conditional_edges(
        "main_agent",
        lambda state: "main_tool_node" if isinstance(state["agent_outcome"], AgentAction) else END,
        {
            "main_tool_node": "main_tool_node",
            END: END
        }
    )
    workflow.add_conditional_edges(
        "main_tool_node",
        route_agent,
        {
            "brave_search_agent": "brave_search_agent",
            "calendar_agent": "calendar_agent",
            "coding_agent": "coding_agent",
            "document_agent": "document_agent",
            "email_agent": "email_agent",
            "finance_agent": "finance_agent",
            "task_agent": "task_agent",
            "__end__": END # Fallback if no specific agent is found
        }
    )

    # Suite-specific agent logic
    for suite_name, tools_list in {
        "brave_search": BRAVE_SEARCH_TOOLS,
        "calendar": CALENDAR_TOOLS,
        "coding": CODING_TOOLS,
        "document": DOCUMENT_TOOLS,
        "email": EMAIL_TOOLS,
        "finance": FINANCE_TOOLS,
        "task": TASK_TOOLS,
    }.items():
        agent_node_name = f"{suite_name}_agent"
        tool_node_name = f"{suite_name}_tool_node"

        workflow.add_conditional_edges(
            agent_node_name,
            lambda state: tool_node_name if isinstance(state["agent_outcome"], AgentAction) else END,
            {
                tool_node_name: tool_node_name,
                END: END
            }
        )
        workflow.add_edge(tool_node_name, END) # After tool execution, return to main flow or end

    return workflow.compile()