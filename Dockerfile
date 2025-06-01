# CryBot Docker Container
FROM crystallang/crystal:1.9.2-alpine

LABEL maintainer="dineth nethsara <hexlorddev@github.com>"
LABEL description="CryBot - Voice-Controlled Terminal Assistant"

# Install dependencies
RUN apk add --no-cache \
    alsa-utils \
    espeak \
    python3 \
    py3-pip \
    git \
    curl \
    bash

# Install Whisper for voice recognition
RUN pip3 install openai-whisper

# Create app directory
WORKDIR /app

# Copy source code
COPY . .

# Install Crystal dependencies
RUN shards install

# Build the application
RUN crystal build src/crybot.cr --release --static

# Create non-root user
RUN adduser -D -s /bin/bash crybot
RUN chown -R crybot:crybot /app

USER crybot

# Expose volume for logs and config
VOLUME ["/app/logs", "/app/plugins"]

# Set environment variables
ENV CRYBOT_CONFIG_FILE=/app/crybot_config.json
ENV CRYBOT_LOG_DIR=/app/logs

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD pgrep crybot || exit 1

# Default command
CMD ["./crybot"]