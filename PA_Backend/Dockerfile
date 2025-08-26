# Dockerfile

# 1. Use an official Python runtime as a parent image
FROM python:3.12-slim

# 2. Set the working directory in the container
WORKDIR /app

# 3. Copy the pyproject.toml and poetry.lock files
COPY pyproject.toml ./

# 4. Install Poetry and dependencies
RUN pip install poetry && poetry install --no-root --only main --no-interaction --no-ansi

# 5. Copy your application code into the container's '/app' directory
COPY . .

# 6. Make port 5000 available to the world outside this container
EXPOSE 5000

# 7. Run main:app with uvicorn when the container launches
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "5000"]
