import os
import re
from pathlib import Path
from typing import Optional, List, Dict
from fastapi import HTTPException
from sqlmodel import Session
from ncc_service import NCCService
from routers import (
    brave_search,
    calendar_crud,
    coding_crud,
    documents_crud,
    email_crud,
    tasks_crud,
)
from routers.finance import crud as finance_crud
from models import User, CalendarEvent, CodeFile, Document, Email, Task, Transaction, Asset, Category
from routers.calendar_schemas import CalendarEventCreate
from routers.coding_schemas import CodeFileCreate
from routers.documents_schemas import DocumentCreate
from routers.email_schemas import EmailCreate
from routers.tasks_schemas import TaskCreate
from routers.finance.schemas import TransactionCreate, AssetCreate, CategoryCreate

# Initialize NCCService
ncc_service = NCCService()

# --- Project Root Configuration ---
PROJECT_ROOT = Path(__file__).parent.parent.absolute()

def _resolve_path(relative_path: str) -> Path:
    """Resolves a relative path to an absolute path within the project root."""
    return PROJECT_ROOT / relative_path

# --- File System Tools (for project-level code management) ---

def read_project_file_tool(relative_file_path: str) -> str:
    """Reads the content of a file within the project.
    Args:
        relative_file_path: The path to the file relative to the project root.
    Returns:
        The content of the file as a string.
    Raises:
        HTTPException: If the file is not found or cannot be read.
    """
    absolute_path = _resolve_path(relative_file_path)
    try:
        return absolute_path.read_text()
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail=f"File not found: {relative_file_path}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error reading file {relative_file_path}: {e}")

def write_project_file_tool(relative_file_path: str, content: str) -> None:
    """Writes content to a file within the project. Creates the file if it doesn't exist.
    Args:
        relative_file_path: The path to the file relative to the project root.
        content: The content to write to the file.
    Raises:
        HTTPException: If the file cannot be written.
    """
    absolute_path = _resolve_path(relative_path)
    try:
        absolute_path.parent.mkdir(parents=True, exist_ok=True)
        absolute_path.write_text(content)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error writing to file {relative_file_path}: {e}")

def list_project_directory_tool(relative_path: str = ".") -> List[str]:
    """Lists the names of files and subdirectories directly within a specified directory relative to the project root.
    Args:
        relative_path: The path to the directory relative to the project root. Defaults to the project root.
    Returns:
        A list of file and directory names.
    Raises:
        HTTPException: If the directory is not found or cannot be listed.
    """
    absolute_path = _resolve_path(relative_path)
    try:
        return [entry.name for entry in absolute_path.iterdir()]
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail=f"Directory not found: {relative_path}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error listing directory {relative_path}: {e}")

def search_project_files_tool(pattern: str, relative_path: str = ".", include: Optional[str] = None) -> List[Dict]:
    """Searches for a regular expression pattern within the content of files in a specified directory relative to the project root.
    Args:
        pattern: The regular expression (regex) pattern to search for.
        relative_path: The path to the directory relative to the project root to search within. Defaults to the project root.
        include: Optional glob pattern to filter which files are searched (e.g., '*.py', '*.{ts,tsx}').
    Returns:
        A list of dictionaries, each containing 'file_path', 'line_number', and 'line_content' for matches.
    Raises:
        HTTPException: If there's an error during search.
    """
    results = []
    search_dir = _resolve_path(relative_path)

    if not search_dir.is_dir():
        raise HTTPException(status_code=400, detail=f"Provided path is not a directory: {relative_path}")

    for root, _, files in os.walk(search_dir):
        for file_name in files:
            file_path = Path(root) / file_name
            if include and not file_path.match(include):
                continue
            try:
                with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                    for line_num, line_content in enumerate(f, 1):
                        if re.search(pattern, line_content):
                            results.append({
                                "file_path": str(file_path.relative_to(PROJECT_ROOT)),
                                "line_number": line_num,
                                "line_content": line_content.strip()
                            })
            except Exception as e:
                # Log or handle errors for individual files, but don't stop the whole search
                print(f"Warning: Could not read file {file_path} during search: {e}")
    return results

def glob_project_files_tool(pattern: str, relative_path: str = ".") -> List[str]:
    """Finds files matching a glob pattern within a specified directory relative to the project root.
    Args:
        pattern: The glob pattern to match against (e.g., '**/*.py', 'docs/*.md').
        relative_path: The path to the directory relative to the project root to search within. Defaults to the project root.
    Returns:
        A list of absolute paths to matching files.
    """
    search_dir = _resolve_path(relative_path)
    matching_files = [str(p.relative_to(PROJECT_ROOT)) for p in search_dir.glob(pattern) if p.is_file()]
    return matching_files

# --- Brave Search Tools ---
async def brave_search_tool(query: str) -> dict:
    """Performs a web search using Brave Search."""
    try:
        response = await brave_search.brave_search(brave_search.SearchQuery(query=query))
        return response
    except HTTPException as e:
        return {"error": e.detail}

# --- Calendar Tools ---
def create_calendar_event_tool(
    user_id: int,
    title: str,
    start_time: str, # Assuming ISO format string
    end_time: str,   # Assuming ISO format string
    db: Session
) -> CalendarEvent:
    """Creates a new calendar event for the user."""
    event_data = CalendarEventCreate(title=title, start_time=start_time, end_time=end_time)
    return calendar_crud.create_calendar_event(db=db, event=event_data, user_id=user_id)

def get_calendar_events_tool(user_id: int, db: Session, skip: int = 0, limit: int = 100) -> List[CalendarEvent]:
    """Retrieves calendar events for the user."""
    return calendar_crud.get_calendar_events(db=db, user_id=user_id, skip=skip, limit=limit)

# --- Coding Tools ---
def create_code_file_tool(
    user_id: int,
    filename: str,
    content: str,
    language: str,
    db: Session
) -> CodeFile:
    """Creates a new code file for the user."""
    code_file_data = CodeFileCreate(filename=filename, content=content, language=language)
    return coding_crud.create_code_file(db=db, code_file=code_file_data, user_id=user_id)

def get_code_files_tool(user_id: int, db: Session, skip: int = 0, limit: int = 100) -> List[CodeFile]:
    """Retrieves code files for the user."""
    return coding_crud.get_code_files(db=db, user_id=user_id, skip=skip, limit=limit)

def update_code_file_tool(
    user_id: int,
    code_file_id: int,
    db: Session,
    filename: Optional[str] = None,
    content: Optional[str] = None,
    language: Optional[str] = None,
) -> CodeFile:
    """Updates an existing code file for the user. Ensures user_id matches the owner."""
    db_code_file = coding_crud.get_code_file(db, code_file_id)
    if not db_code_file or db_code_file.user_id != user_id:
        raise HTTPException(status_code=404, detail="Code file not found or not owned by user")
    
    update_data = {}
    if filename is not None:
        update_data["filename"] = filename
    if content is not None:
        update_data["content"] = content
    if language is not None:
        update_data["language"] = language

    code_file_data = CodeFileCreate(**update_data)
    return coding_crud.update_code_file(db=db, code_file_id=code_file_id, code_file=code_file_data)

def delete_code_file_tool(user_id: int, code_file_id: int, db: Session) -> dict:
    """Deletes a code file for the user. Ensures user_id matches the owner."""
    db_code_file = coding_crud.get_code_file(db, code_file_id)
    if not db_code_file or db_code_file.user_id != user_id:
        raise HTTPException(status_code=404, detail="Code file not found or not owned by user")
    return coding_crud.delete_code_file(db=db, code_file_id=code_file_id)

# --- Documents Tools ---
def create_document_tool(
    user_id: int,
    title: str,
    content: str,
    db: Session
) -> Document:
    """Creates a new document for the user."""
    document_data = DocumentCreate(title=title, content=content)
    return documents_crud.create_document(db=db, document=document_data, user_id=user_id)

def get_documents_tool(user_id: int, db: Session, skip: int = 0, limit: int = 100) -> List[Document]:
    """Retrieves documents for the user."""
    return documents_crud.get_documents(db=db, user_id=user_id, skip=skip, limit=limit)

# --- Email Tools ---
def create_email_tool(
    user_id: int,
    subject: str,
    sender: str,
    recipients: str,
    body: str,
    db: Session
) -> Email:
    """Creates a new email entry for the user."""
    email_data = EmailCreate(subject=subject, sender=sender, recipients=recipients, body=body)
    return email_crud.create_email(db=db, email=email_data, user_id=user_id)

def get_emails_tool(user_id: int, db: Session, skip: int = 0, limit: int = 100) -> List[Email]:
    """Retrieves emails for the user."""
    return email_crud.get_emails(db=db, user_id=user_id, skip=skip, limit=limit)

# --- Finance Tools ---
def create_transaction_tool(
    user_id: int,
    date: str, # Assuming ISO format string
    description: str,
    amount: float,
    category_id: int,
    db: Session
) -> Transaction:
    """Creates a new financial transaction for the user."""
    transaction_data = TransactionCreate(date=date, description=description, amount=amount, category_id=category_id)
    return finance_crud.create_transaction(db=db, transaction=transaction_data, user_id=user_id)

def get_transactions_tool(user_id: int, db: Session, skip: int = 0, limit: int = 100) -> List[Transaction]:
    """Retrieves financial transactions for the user."""
    return finance_crud.get_transactions(db=db, user_id=user_id, skip=skip, limit=limit)

def create_asset_tool(
    user_id: int,
    name: str,
    value: float,
    db: Session
) -> Asset:
    """Creates a new asset entry for the user."""
    asset_data = AssetCreate(name=name, value=value)
    return finance_crud.create_asset(db=db, asset=asset_data, user_id=user_id)

def get_assets_tool(user_id: int, db: Session, skip: int = 0, limit: int = 100) -> List[Asset]:
    """Retrieves assets for the user."""
    return finance_crud.get_assets(db=db, user_id=user_id, skip=skip, limit=limit)

def create_category_tool(
    name: str,
    db: Session
) -> Category:
    """Creates a new transaction category."""
    category_data = CategoryCreate(name=name)
    return finance_crud.create_category(db=db, category=category_data)

def get_categories_tool(db: Session, skip: int = 0, limit: int = 100) -> List[Category]:
    """Retrieves transaction categories."""
    return finance_crud.get_categories(db=db, skip=skip, limit=limit)

# --- Tasks Tools ---
def create_task_tool(
    user_id: int,
    title: str,
    is_completed: bool,
    db: Session
) -> Task:
    """Creates a new task for the user."""
    task_data = TaskCreate(title=title, is_completed=is_completed)
    return tasks_crud.create_task(db=db, task=task_data, user_id=user_id)

def get_tasks_tool(user_id: int, db: Session, skip: int = 0, limit: int = 100) -> List[Task]:
    """Retrieves tasks for the user."""
    return tasks_crud.get_tasks(db=db, user_id=user_id, skip=skip, limit=limit)

# --- Generic Compute Tool (Leveraging NCC) ---
async def run_ncc_compute_tool(python_code: str, input_data: Optional[str] = None) -> str:
    """
    Executes arbitrary Python code on the NCC supercomputer.
    Use this for computationally intensive tasks that cannot be handled locally.
    The `python_code` should be a self-contained Python script.
    Optionally, `input_data` can be provided as a string, which will be available
    to the script via a temporary file (details to be handled by the NCC script).
    """
    try:
        response = await ncc_service.run_compute_on_ncc(python_code, input_data)
        return response
    except Exception as e:
        return {"error": f"NCC compute failed: {e}"}
