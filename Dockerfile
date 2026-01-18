# Stage 1: Build stage
FROM python:3.10-slim-bullseye as builder

WORKDIR /app
RUN apt-get update && apt-get install -y gcc curl python3-dev
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Stage 2: Final Runtime stage
FROM python:3.10-slim-bullseye

RUN groupadd -r appuser && useradd -r -g appuser appuser
WORKDIR /app

# Copy only the installed packages from builder
COPY --from=builder /root/.local /home/appuser/.local
COPY . .

RUN chown -R appuser:appuser /app
USER appuser

# Ensure the local pip binaries are in the path
ENV PATH=/home/appuser/.local/bin:$PATH \
    PYTHONUNBUFFERED=1

EXPOSE 5000

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "4", "--access-logfile", "-", "app:app"]