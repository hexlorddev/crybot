#!/bin/bash

# CryBot Installation Script
# Author: dineth nethsara (hexlorddev)

set -e

CRYBOT_DIR="$HOME/.crybot"
CRYBOT_BIN="$HOME/.local/bin/crybot"

echo "🧊🤖 CryBot Installation Script"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if Crystal is installed
if ! command -v crystal &> /dev/null; then
    echo "❌ Crystal is not installed!"
    echo "📦 Installing Crystal..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux installation
        curl -fsSL https://crystal-lang.org/install.sh | sudo bash
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS installation
        if command -v brew &> /dev/null; then
            brew install crystal
        else
            echo "❌ Please install Homebrew first: https://brew.sh"
            exit 1
        fi
    else
        echo "❌ Unsupported operating system"
        echo "📖 Please install Crystal manually: https://crystal-lang.org/install/"
        exit 1
    fi
fi

echo "✅ Crystal is available"

# Install voice dependencies
echo "🎤 Installing voice recognition dependencies..."

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux dependencies
    if command -v apt &> /dev/null; then
        sudo apt update
        sudo apt install -y espeak espeak-data alsa-utils python3-pip
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y espeak espeak-data alsa-utils python3-pip
    elif command -v pacman &> /dev/null; then
        sudo pacman -S espeak espeak-data alsa-utils python-pip
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS dependencies
    if command -v brew &> /dev/null; then
        brew install espeak python3
    fi
fi

# Install Whisper for voice recognition
echo "🎙️ Installing Whisper..."
pip3 install --user openai-whisper

# Create directories
echo "📁 Creating directories..."
mkdir -p "$CRYBOT_DIR"
mkdir -p "$(dirname "$CRYBOT_BIN")"
mkdir -p "$CRYBOT_DIR/plugins"
mkdir -p "$CRYBOT_DIR/logs"

# Copy CryBot files
echo "📦 Installing CryBot..."
cp -r src/ "$CRYBOT_DIR/"
cp -r plugins/ "$CRYBOT_DIR/"
cp shard.yml "$CRYBOT_DIR/"

# Build CryBot
echo "🔨 Building CryBot..."
cd "$CRYBOT_DIR"
shards install
crystal build src/crybot.cr --release -o crybot

# Create executable script
cat > "$CRYBOT_BIN" << 'EOF'
#!/bin/bash
cd "$HOME/.crybot"
exec ./crybot "$@"
EOF

chmod +x "$CRYBOT_BIN"

# Add to PATH if not already there
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo "🔧 Adding CryBot to PATH..."
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    echo "📝 Please run: source ~/.bashrc"
fi

# Create desktop entry (Linux only)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    DESKTOP_DIR="$HOME/.local/share/applications"
    mkdir -p "$DESKTOP_DIR"
    
    cat > "$DESKTOP_DIR/crybot.desktop" << EOF
[Desktop Entry]
Name=CryBot
Comment=Voice-Controlled Terminal Assistant
Exec=$CRYBOT_BIN
Icon=applications-system
Terminal=true
Type=Application
Categories=System;Utility;
Keywords=voice;assistant;terminal;ai;
EOF
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ CryBot installation completed!"
echo ""
echo "🚀 Quick Start:"
echo "   crybot                    # Start CryBot"
echo "   crybot --help            # Show help"
echo "   crybot --config          # Edit configuration"
echo ""
echo "🎤 Voice Commands:"
echo "   'Hey CryBot'             # Wake word"
echo "   'open browser'           # Launch browser"
echo "   'show cpu usage'         # System monitoring"
echo "   'help'                   # Show all commands"
echo ""
echo "🔧 Configuration:"
echo "   Config: $CRYBOT_DIR/crybot_config.json"
echo "   Logs:   $CRYBOT_DIR/logs/"
echo "   Plugins: $CRYBOT_DIR/plugins/"
echo ""
echo "📚 Documentation: https://github.com/hexlorddev/crybot"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Test installation
if [ "$1" != "--no-test" ]; then
    echo "🧪 Testing installation..."
    if "$CRYBOT_BIN" --help > /dev/null 2>&1; then
        echo "✅ CryBot is working correctly!"
    else
        echo "❌ Installation test failed"
        exit 1
    fi
fi