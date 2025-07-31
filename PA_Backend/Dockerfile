# Dockerfile

# 1. Use an official Python runtime as a parent image
FROM python:3.12.9-slim

# 2. Set the working directory in the container
WORKDIR /app

# 3. Install Poetry
RUN pip install poetry

# 4. Copy the pyproject.toml and poetry.lock files
COPY pyproject.toml poetry.lock* ./

# 5. Install dependencies
RUN poetry install --no-root --only main --no-interaction --no-ansi

# 6. Copy your application code into the container's '/app' directory
COPY . .

# 7. Make port 5000 available to the world outside this container
EXPOSE 5000

# 8. Run main.py when the container launches
CMD ["poetry", "run", "python", "main.py"]
