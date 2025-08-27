# Project Astra 🌟

Project Astra is an intelligent conversational AI assistant designed to provide versatile support across a range of tasks, including coding, writing, analysis, and general assistance. It leverages a sophisticated ReAct (Reasoning and Acting) framework, allowing it to use tools and maintain context for more insightful interactions.
## ✨ Core Features

- **Conversational Interface:** Engage in natural language dialogues.
- **ReAct Agent:** Utilizes a Thought-Action-Observation loop for problem-solving.
- **Tool Integration:** Capable of using predefined tools (e.g., fetching current time) to enhance responses.
- **Markdown Rendering:** AI responses are formatted in Markdown, supporting rich text, code blocks, and lists.
- **Code Highlighting:** Code snippets in AI responses are syntax-highlighted.
- **LaTeX Support:** Mathematical expressions written in LaTeX are rendered correctly.
- **Persistent Chat History:** Conversations are saved to ensure context and history across sessions.
  - **Backend:** SQLite for long-term storage.
  - **Frontend:** Hive for local caching and quick access.
- **Collapsible Thought Process:** Users can view the AI's underlying thought process for transparency.

## 🛠️ Tech Stack

- **Backend:**
  - Python 3.9+
  - FastAPI (for the REST API)
  - Uvicorn (ASGI server)
  - Langchain & LangGraph (AI agent orchestration)
  - Hugging Face Transformers (LLM interaction)
  - PyTorch
  - FireStore (Database)
- **AI Model:**
  - `deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B` (or other compatible Causal LM)
- **Frontend:**
  - Flutter (Dart)
  - `http` (API communication)
  - `flutter_markdown` (Markdown rendering)
  - `flutter_markdown_latex` (LaTeX rendering for Markdown)
  - `highlight` (Syntax highlighting data)
  - `hive`, `hive_flutter`, `path_provider` (Local persistence)
- **Development & Tooling:**
  - `build_runner`, `hive_generator` (Flutter code generation)

## 📋 Prerequisites

- **Python:** Version 3.9 or higher, with `pip`.
- **Flutter:** Latest stable version of the Flutter SDK and Dart SDK.
- **Git:** For cloning the repository.
- **Internet Connection:** To download models and dependencies.
- **(Optional) NVIDIA GPU & CUDA:** For significantly better backend model inference performance. CPU is supported but will be slower.
- Sufficient RAM/VRAM for the AI model.

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone <YOUR_REPOSITORY_URL>
cd <project-root-directory>
```

### 2. Backend Setup
Navigate to your backend directory (e.g., backend/).
a. Create and Activate Virtual Environment:

```python -m venv venv
# Windows
.\venv\Scripts\activate
# macOS/Linux
source venv/bin/activate
```

### b. Install Dependencies:
(Ensure you have a requirements.txt in your backend folder)

`pip install -r requirements.txt`

Key dependencies: fastapi, uvicorn, torch, transformers, langchain, langchain-huggingface, langgraph.

### c. Initialize Database (SQLite):
If you have a database.py script to create tables:

`
python database.py
`

Alternatively, the FastAPI server might create tables on its first startup. A chat_agent.db file will be created.

### d. AI Model:
The Hugging Face model will be downloaded automatically on the first run if not found in the cache.

### 3. Frontend Setup
   Navigate to your Flutter project directory (e.g., frontend/).

### a. Get Dependencies:

`flutter pub get`

### b. Configure Backend URL:
Locate your API service file (e.g., lib/features/chat/services/chat_api_service.dart) and update the base URL to point to your running backend:

- Android Emulator (to host machine): http://10.0.2.2:8000
- iOS Simulator/Desktop (to host machine): http://localhost:8000
- Physical Device (same network): http://<YOUR_COMPUTER_LOCAL_IP>:8000

### c. Generate Hive Adapters:
(After annotating your ChatMessage and MessageType models for Hive)

`flutter pub run build_runner build --delete-conflicting-outputs`

Ensure your main.dart initializes Hive and registers adapters.

⚡ Running Project Astra
Start the Backend Server:
From your backend directory (with venv activated):

`uvicorn main_server:app --host 0.0.0.0 --port 8000 --reload`

Watch the terminal for "Application startup complete" and AI agent initialization messages.

Run the Flutter Application:
From your frontend directory, with a device/emulator running or browser selected:

`flutter run`
````
📁 Project Structure (Simplified Example)
<project-root-directory>/
├── backend/
│   ├── main_agent.py       # AI logic, Langchain agent
│   ├── main_server.py      # FastAPI app, API endpoints
│   ├── database.py         # SQLite setup
│   ├── chat_agent.db       # SQLite database file
│   └── requirements.txt
│
├── frontend/               # Flutter application
│   ├── lib/
│   │   ├── main.dart         # App entry, Hive initialization
│   │   └── features/chat/    # Chat feature module
│   │       ├── models/chat_models.dart (.g.dart)
│   │       ├── services/chat_api_service.dart
│   │       ├── ui/chat_panel.dart
│   │       └── widgets/chat_message_bubble.dart
│   ├── assets/             # Images like AstraPfP.png
│   └── pubspec.yaml
│
└── README.md
````
## 💬 How to Use
Once both backend and frontend are running, the chat interface will be available.

Type messages to interact with Astra.

For AI responses, the "Thought:" section can be expanded to see the agent's reasoning steps.

## 🛣️ Potential Roadmap / Future Work
-User authentication and personalized experiences.

-Expansion of toolset for the AI agent.

-More advanced memory and context management.

-Cloud deployment for backend and database.

-Voice interaction capabilities.

UI/UX refinements.
````
