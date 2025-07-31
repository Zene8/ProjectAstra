import os
from dotenv import load_dotenv

load_dotenv()

MODEL_NAME = os.getenv("MODEL_NAME", "deepseek-ai/deepseek-llm")

# Database Config
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql+asyncpg://user:password@db/app")

# NCC Config
NCC_USER = os.getenv("NCC_USER")
NCC_HOST = os.getenv("NCC_HOST")
NCC_PRIVATE_KEY_PATH = os.getenv("NCC_PRIVATE_KEY_PATH")
NCC_REMOTE_JOB_DIR = os.getenv("NCC_REMOTE_JOB_DIR", "/path/to/remote/jobs")
NCC_REMOTE_INFERENCE_SCRIPT_PATH = os.getenv("NCC_REMOTE_INFERENCE_SCRIPT_PATH", "/path/to/your/inference/script.py")
NCC_REMOTE_VENV_PATH = os.getenv("NCC_REMOTE_VENV_PATH", "/path/to/your/venv/bin/activate")

# Brave Search API Config
BRAVE_SEARCH_API_KEY = os.getenv("BRAVE_SEARCH_API_KEY")
