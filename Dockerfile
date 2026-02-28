# --- Stage 1: Builder ---
FROM python:3.10-slim-bullseye as builder

WORKDIR /app
RUN apt-get update && apt-get install -y gcc python3-dev

COPY requirements.txt .
# We install everything into the /install folder
RUN pip install --prefix=/install --no-cache-dir -r requirements.txt

# --- Stage 2: Final (Distroless) ---
FROM gcr.io/distroless/python3-debian11:nonroot

WORKDIR /app

# Copy the prefix-installed packages directly into /usr/local
# This places gunicorn in /usr/local/bin and libs in /usr/local/lib
COPY --from=builder /install /usr/local
COPY --chown=nonroot:nonroot . .

# Set the path so the system finds the gunicorn module
ENV PYTHONPATH=/usr/local/lib/python3.10/site-packages
ENV PYTHONUNBUFFERED=1

EXPOSE 5000

# Since there is no shell, we call gunicorn as a module via python
CMD ["/usr/bin/python3", "-m", "gunicorn", "--bind", "0.0.0.0:5000", "app:app"]