# CryBot Makefile
# Author: dineth nethsara (hexlorddev)

.PHONY: build install test clean help run dev

# Default target
all: build

# Build CryBot
build:
	@echo "🔨 Building CryBot..."
	@crystal build src/crybot.cr --release
	@echo "✅ Build complete!"

# Development build (faster compilation)
dev:
	@echo "🔨 Building CryBot (development)..."
	@crystal build src/crybot.cr
	@echo "✅ Development build complete!"

# Install dependencies
deps:
	@echo "📦 Installing dependencies..."
	@shards install
	@echo "✅ Dependencies installed!"

# Run CryBot
run:
	@crystal run src/crybot.cr

# Run in mock mode (no voice required)
mock:
	@crystal run src/crybot.cr -- --mock-voice

# Run tests
test:
	@echo "🧪 Running tests..."
	@crystal run test_crybot.cr
	@echo "✅ Tests complete!"

# Install CryBot system-wide
install:
	@echo "📦 Installing CryBot..."
	@./install.sh
	@echo "✅ Installation complete!"

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -f crybot
	@rm -f test_config.json
	@rm -f test.crylog
	@rm -f *.tmp
	@echo "✅ Clean complete!"

# Format code
format:
	@echo "💅 Formatting code..."
	@crystal tool format src/
	@echo "✅ Code formatted!"

# Check for issues
check:
	@echo "🔍 Checking code..."
	@crystal tool format --check src/
	@crystal build src/crybot.cr --no-codegen
	@echo "✅ Code check complete!"

# Docker build
docker:
	@echo "🐳 Building Docker image..."
	@docker build -t crybot:latest .
	@echo "✅ Docker image built!"

# Docker run
docker-run:
	@echo "🐳 Running CryBot in Docker..."
	@docker run -it --rm \
		--device /dev/snd \
		-v $(PWD)/plugins:/app/plugins \
		-v $(PWD)/logs:/app/logs \
		crybot:latest

# Show available commands
help:
	@echo "🧊🤖 CryBot Build Commands:"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  build      - Build CryBot (release mode)"
	@echo "  dev        - Build CryBot (development mode)"
	@echo "  deps       - Install Crystal dependencies"
	@echo "  run        - Run CryBot"
	@echo "  mock       - Run CryBot in mock mode (no voice)"
	@echo "  test       - Run test suite"
	@echo "  install    - Install CryBot system-wide"
	@echo "  clean      - Clean build artifacts"
	@echo "  format     - Format source code"
	@echo "  check      - Check code for issues"
	@echo "  docker     - Build Docker image"
	@echo "  docker-run - Run CryBot in Docker"
	@echo "  help       - Show this help message"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Print project info
info:
	@echo "🧊🤖 CryBot - Voice-Controlled Terminal Assistant"
	@echo "Author: dineth nethsara (hexlorddev)"
	@echo "Language: Crystal"
	@echo "Version: 1.0.0"
	@echo "License: MIT"