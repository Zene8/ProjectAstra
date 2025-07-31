
# AI Agent Orchestration Server

This project implements a robust orchestration server for an AI agent, designed to manage user interactions and offload computationally intensive LLM inference to a remote SLURM cluster.

## Features

- **FastAPI Backend:** A modern, fast (high-performance) web framework for building APIs.
- **PostgreSQL Database:** A powerful, open-source object-relational database system for persisting chat history.
- **Docker Compose:** A tool for defining and running multi-container Docker applications.
- **NCC Integration:** Offloads LLM inference to the Durham University NCC Supercomputer via SSH and SLURM.

## Getting Started

### Prerequisites

- Docker
- Docker Compose
- Access to the Durham University NCC Supercomputer (or another SLURM cluster)

### Configuration

1.  **Clone the repository:**
    ```bash
    git clone <repository_url>
    cd <repository_directory>
    ```

2.  **Create a `.env` file:**
    Create a `.env` file in the root of the project and add the following environment variables:

    ```env
    DATABASE_URL=postgresql+asyncpg://user:password@db/app
    NCC_USER=your_ncc_user
    NCC_HOST=your_ncc_host
    NCC_PRIVATE_KEY_PATH=/path/to/your/private/key
    NCC_REMOTE_JOB_DIR=/path/to/remote/jobs
    NCC_REMOTE_INFERENCE_SCRIPT_PATH=/path/to/your/inference/script.py
    NCC_REMOTE_VENV_PATH=/path/to/your/venv/bin/activate
    ```

    Replace the placeholder values with your actual NCC credentials and paths.

3.  **Place the inference script on the NCC:**
    Copy the `ncc/inference.py` script to the path specified in `NCC_REMOTE_INFERENCE_SCRIPT_PATH` on your NCC machine.

### Running the Application

1.  **Build and run the Docker containers:**
    ```bash
    docker-compose up --build
    ```

    This will start the FastAPI server and the PostgreSQL database.

2.  **Access the API:**
    The API will be available at `http://localhost:5000`. You can interact with the AI agent by sending POST requests to the `/chat` endpoint.

    **Example Request:**
    ```bash
    curl -X POST "http://localhost:5000/chat" -H "Content-Type: application/json" -d '{"username": "testuser", "message": "Hello, world!"}'
    ```

## Project Structure

```
.
├── .dockerignore
├── .env
├── .gitignore
├── config.py
├── database.py
├── docker-compose.yml
├── Dockerfile
├── main.py
├── models.py
├── ncc
│   └── inference.py
├── README.md
├── req.txt
└── static
    └── index.html
```
