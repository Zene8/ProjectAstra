
# Project Astra: Development Plan

## 1. Project Overview & Vision

Project Astra aims to be a personal AI agent orchestration platform, providing a unified interface for users to interact with various AI capabilities and manage their digital life. The core idea is to offload computationally intensive AI tasks to a powerful backend while offering a smooth, intuitive, and highly customizable user experience on the frontend.

**Vision:** To create a seamless, intelligent, and extensible personal AI assistant that integrates deeply with user workflows and external services.

## 2. Architecture Overview

### 2.1. Frontend (PA_Flutter)

*   **Technology:** Flutter (Dart) for cross-platform desktop applications.
*   **Key Components:**
    *   **App Shell:** Manages the overall application structure, navigation, and window management.
    *   **Desktop Navbar:** Provides core navigation, application launching, and taskbar-like window management.
    *   **Main Content Desktop:** Manages the display and interaction of individual application windows (widgets).
    *   **Theming System:** Dynamic theme switching based on Dart-defined themes.
    *   **Widgets/Pages:** Individual application modules (Chat, Calendar, Tasks, Email, Finance, Search, Docs, Code, User Settings).
    *   **Authentication:** Firebase Authentication integration.
    *   **Hotkey Manager:** Global hotkey support for enhanced window management.

### 2.2. Backend (PA_Backend)

*   **Technology:** FastAPI (Python) for a high-performance asynchronous API.
*   **Database:** PostgreSQL (via SQLModel) for persistent storage of user data, chat history, and application-specific data (e.g., calendar events, tasks, finance transactions).
*   **Containerization:** Docker and Docker Compose for easy setup and deployment.
*   **AI Offloading (NCC Integration):** Secure SSH and SLURM integration to offload computationally intensive LLM inference to a remote supercomputer (Durham University NCC).
*   **External Service Integrations:**
    *   Google Calendar API
    *   Google Tasks API
    *   Google Gmail API
    *   Brave Search API

### 2.3. Backend (PA_Java_Services)

*   **Technology:** Spring Boot (Java) for microservices.
*   **Services:**
    *   **auth-service:** Handles user authentication and authorization.
    *   **finance-service:** Provides financial data and reporting.

## 3. Development Phases & Roadmap

### Phase 1: Minimum Viable Product (MVP) - Core Functionality & Basic Suites

**Goal:** Deliver a stable, functional, and aesthetically pleasing core application with essential features and basic integrations.

*   **Core Features:**
    *   User Authentication (Sign-up, Login, Logout, Profile Management).
    *   Main Chat Functionality (User input, AI response, history, SLURM integration).
    *   Basic Web Search Integration.
*   **Basic Suites (Functional, but not exhaustive):**
    *   **Calendar:** Local event management (CRUD) and Google Calendar API integration (read-only).
    *   **Tasks:** Local task management (CRUD) and Google Tasks API integration (read-only).
    *   **Email:** Local email management (CRUD) and Google Gmail API integration (read-only).
    *   **Finance:** Local transaction/asset/category management (CRUD) and CSV upload.
    *   **Coding:** Basic code execution.
    *   **Documents:** Basic Google Drive integration (read-only).
*   **Frontend Enhancements:**
    *   Refined Navbar (translucent, Chrome-like tabs, logo as home, chat icon).
    *   Improved Window Management (minimize/maximize/close, sticky windows, snap layouts with visual picker, hotkeys).
    *   Dynamic Theming System.

### Phase 1.5: Enhanced Suites & Initial Linking

**Goal:** Deepen the functionality of the basic suites and introduce initial inter-window linking.

*   **Enhanced Suites:**
    *   **Calendar:** Add create/update/delete for Google Calendar events.
    *   **Tasks:** Add create/update/delete for Google Tasks.
    *   **Email:** Add send/compose functionality for Gmail.
    *   **Finance:** Implement more advanced financial reporting and analysis.
*   **Window Management:**
    *   **Adjacent Window Linking:** Implement robust linking of adjacent windows (move/resize together).
    *   **Smart Layouts:** Refine layout logic to prevent overlaps and suggest optimal arrangements.
    *   **Layout Previews:** Enhance the snap UI with more detailed visual previews.

### Phase 2: Advanced AI Capabilities & Deeper Integrations

**Goal:** Integrate more sophisticated AI features and expand external service integrations.

*   **Advanced AI:**
    *   Contextual AI understanding across applications.
    *   Proactive suggestions and automation.
    *   Personalized learning and adaptation.
*   **Deeper Integrations:**
    *   Microsoft Office 365 (Outlook, OneDrive, To Do).
    *   Project Management Tools (Jira, Trello).
    *   Communication Platforms (Slack, Discord).
*   **Customizable Workflows:** Allow users to define custom automation rules.

## 4. Current Status Evaluation

Based on the plan above, here's where we stand:

### Frontend (PA_Flutter)

*   **Navbar Redesign:** **COMPLETE** (translucent, Chrome-like tabs, logo as home, chat icon, thinner tabs).
*   **Window Management:**
    *   Minimize/Restore from Taskbar: **COMPLETE**
    *   Minimize Animation: **COMPLETE**
    *   Permanent Close: **COMPLETE** (already handled by `_closeWidget`).
    *   Sticky Windows: **COMPLETE**
    *   Snap Layouts with Visual Picker: **COMPLETE**
    *   Hotkeys for Layouts: **COMPLETE** (using `hotkey_manager`).
    *   Adjacent Window Linking: **COMPLETE**
    *   Smart Layouts (intelligent overlap resolution): **COMPLETE**
    *   Layout Previews (in snap dialog): **COMPLETE**
*   **Theming System:** **COMPLETE** (Dart-based themes, theme picker).
*   **Google Service Connection Options:** **COMPLETE** (Calendar, Tasks, Gmail connection buttons in User Settings).
*   **Widget Content Expansion:** **COMPLETE** (Docs and Code editors fill window).

### Backend (PA_Backend)

*   **Core Services (Auth, Chat, Brave Search):** **COMPLETE**
*   **Phase 1 MVP - Remaining Routers:**
    *   `coding.py`: **COMPLETE** (basic `run_code` endpoint, local CRUD for code files implemented).
    *   `documents.py`: **COMPLETE** (Google Drive integration with OAuth, local CRUD for documents implemented).
    *   `messages.py`: **COMPLETE** (Full CRUD for local messages).
*   **Phase 1.5 - Basic Suites Implementation:**
    *   **Calendar:** **COMPLETE**
    *   **Tasks:** **COMPLETE**
    *   **Email:** **COMPLETE**
    *   **Finance:** **COMPLETE**

### Backend (PA_Java_Services)

*   **auth-service:** **IN PROGRESS** (Basic security configuration implemented).
*   **finance-service:** **IN PROGRESS** (Basic CRUD service for transactions implemented).

## 5. To-Do List (Next Immediate Steps)

With the completion of Phase 1.5, the next steps will focus on Phase 2.

1.  **Advanced AI:**
    *   Contextual AI understanding across applications.
    *   Proactive suggestions and automation.
    *   Personalized learning and adaptation.
2.  **Deeper Integrations:**
    *   Microsoft Office 365 (Outlook, OneDrive, To Do).
    *   Project Management Tools (Jira, Trello).
    *   Communication Platforms (Slack, Discord).
3.  **Customizable Workflows:** Allow users to define custom automation rules.

## 6. Coding Standards & Conventions

*   **Language:** Dart (Flutter) for frontend, Python (FastAPI) and Java (Spring Boot) for backend.
*   **Formatting:** Adhere to `dart format` for Flutter and `black` for Python.
*   **Naming Conventions:**
    *   Dart: `camelCase` for variables/functions, `PascalCase` for classes, `snake_case` for file names.
    *   Python: `snake_case` for variables/functions/files, `PascalCase` for classes.
*   **Comments:** Use comments to explain *why* complex logic is implemented, not *what* it does.
*   **Error Handling:** Implement robust error handling on both frontend and backend, providing clear feedback to the user.
*   **Modularity:** Keep components small, focused, and reusable.

## 7. CI/CD Considerations

*   **Automated Testing:** Implement unit and integration tests for both frontend and backend.
*   **Linting/Static Analysis:** Integrate linters (e.g., `flutter analyze`, `flake8`, `mypy`) into the CI pipeline.
*   **Docker Builds:** Automate Docker image builds for the backend.
*   **Deployment:** Define deployment strategies for both frontend (desktop installers) and backend (container orchestration).

## 8. Getting Started for New Developers

### Frontend (PA_Flutter)

1.  **Install Flutter:** Follow the official Flutter installation guide for your OS.
2.  **Clone Repository:** `git clone <repo_url>`
3.  **Navigate to Frontend:** `cd PA_Flutter`
4.  **Get Dependencies:** `flutter pub get`
5.  **Run Application:** `flutter run -d windows` (or your preferred desktop platform).

### Backend (PA_Backend)

1.  **Install Docker & Docker Compose:** Follow official Docker documentation.
2.  **Clone Repository:** `git clone <repo_url>`
3.  **Navigate to Backend:** `cd PA_Backend`
4.  **Create `.env` file:** Copy `.env.example` (if exists) or create a new `.env` file with necessary environment variables (DATABASE_URL, NCC credentials, etc.).
5.  **Build & Run:** `docker-compose up --build`
6.  **Access API Docs:** `http://localhost:5000/docs` (Swagger UI)

### Backend (PA_Java_Services)

1.  **Install Java 17 and Maven.**
2.  **Navigate to the service directory (e.g., `PA_Java_Services/auth-service`).**
3.  **Run the application:** `mvn spring-boot:run`
