import os
from dotenv import load_dotenv

load_dotenv()

# AI Model Configuration
AI_MODELS = {
    "phi-3-mini": {
        "name": "phi-3-mini",
        "type": "local",
        "description": "Microsoft's Phi-3 Mini (3.8B parameters), suitable for general tasks on low-end hardware.",
        "model_path": os.getenv("PHI3_MINI_MODEL_PATH", "./models/phi-3-mini.gguf"),
    },
    "gemma-2b": {
        "name": "gemma-2b",
        "type": "local",
        "description": "Google's Gemma 2B, a lightweight general-purpose model.",
        "model_path": os.getenv("GEMMA_2B_MODEL_PATH", "./models/gemma-2b.gguf"),
    },
    "codegemma-2b": {
        "name": "codegemma-2b",
        "type": "local",
        "description": "Google's CodeGemma 2B, optimized for code generation and understanding.",
        "model_path": os.getenv("CODEGEMMA_2B_MODEL_PATH", "./models/codegemma-2b.gguf"),
    },
    "deepseek-coder-1.3b": {
        "name": "deepseek-coder-1.3b",
        "type": "local",
        "description": "DeepSeek Coder 1.3B, a small but capable model for coding tasks.",
        "model_path": os.getenv("DEEPSEEK_CODER_1_3B_MODEL_PATH", "./models/deepseek-coder-1.3b.gguf"),
    },
    "deepseek-llm": {
        "name": "deepseek-llm",
        "type": "ncc",
        "description": "DeepSeek LLM, running on the NCC supercomputer.",
        "inference_script": os.getenv("NCC_DEEPSEEK_INFERENCE_SCRIPT", "/path/to/ncc/deepseek_inference.py"),
        "venv_path": os.getenv("NCC_DEEPSEEK_VENV_PATH", "/path/to/ncc/deepseek_venv/bin/activate"),
    },
}

DEFAULT_AI_MODEL = os.getenv("DEFAULT_AI_MODEL", "lightweight-local")



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
