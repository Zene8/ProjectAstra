import os
from dotenv import load_dotenv

load_dotenv()

# NCC Config
NCC_USER = os.getenv("NCC_USER")
NCC_HOST = os.getenv("NCC_HOST")
NCC_PRIVATE_KEY_PATH = os.getenv("NCC_PRIVATE_KEY_PATH")
NCC_REMOTE_JOB_DIR = os.getenv("NCC_REMOTE_JOB_DIR", "/path/to/remote/jobs")
NCC_REMOTE_INFERENCE_SCRIPT_PATH = os.getenv("NCC_REMOTE_INFERENCE_SCRIPT_PATH", "/path/to/your/inference/script.py")
NCC_REMOTE_VENV_PATH = os.getenv("NCC_REMOTE_VENV_PATH", "/path/to/your/venv/bin/activate")
