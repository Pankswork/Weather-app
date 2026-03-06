# --- Stage 1: Builder ---
FROM python:3.11-alpine as builder

WORKDIR /app
# Install build dependencies for alpine
RUN apk add --no-cache gcc musl-dev python3-dev libffi-dev

COPY requirements.txt .
# Upgrade build tools to patch python module CVEs like jaraco.context and wheel
RUN pip install --upgrade pip setuptools wheel jaraco.context
# We install everything into the /install folder
RUN pip install --prefix=/install --no-cache-dir -r requirements.txt

# --- Stage 2: Final ---
FROM python:3.11-alpine

WORKDIR /app

# Copy the prefix-installed packages directly into /usr/local
COPY --from=builder /install /usr/local
COPY . .

# Run as a non-root user for security
# Provide a security patch for zlib in the final stage
RUN apk add --no-cache --upgrade zlib && \
    pip install --no-cache-dir --upgrade pip setuptools wheel jaraco.context && \
    addgroup -S nonroot && adduser -S nonroot -G nonroot && \
    chown -R nonroot:nonroot /app

USER nonroot

ENV PYTHONPATH=/usr/local/lib/python3.11/site-packages
ENV PYTHONUNBUFFERED=1

EXPOSE 5000

CMD ["python", "-m", "gunicorn", "--bind", "0.0.0.0:5000", "app:app"]