
# Stage 1: Build and install dependencies
FROM python:3.11-slim AS builder


# Set environment variables for security and performance
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONPATH=/app


# Create non-root user for security
RUN groupadd --gid 1000 appuser && \
    useradd --uid 1000 --gid 1000 --create-home --shell /bin/bash appuser


# Update system packages and install security updates, then remove cache
RUN apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


# Set working directory
WORKDIR /app


# Copy requirements first for better caching
COPY requirements.txt .


# Upgrade pip and install dependencies
RUN pip install --upgrade pip setuptools wheel && \
    pip install --no-cache-dir -r requirements.txt


# Copy application code
COPY app.py .


# Change ownership of app directory to non-root user
RUN chown -R appuser:appuser /app


# Final stage: Use distroless Python for minimal attack surface
FROM gcr.io/distroless/python3-debian12
WORKDIR /app
COPY --from=builder /app /app
USER 1000:1000


EXPOSE 8080


# Healthcheck is not supported in distroless, so skip it


CMD ["python3", "-m", "flask", "run", "--host=0.0.0.0", "--port=8080"]
