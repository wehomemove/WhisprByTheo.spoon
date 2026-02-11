#!/bin/bash
#
# WhisprByTheo dependency installer
# Installs mlx-whisper and ffmpeg for Apple Silicon Macs
#

set -e

echo "🎙️  WhisprByTheo Dependency Installer"
echo "====================================="
echo ""

# Check for Apple Silicon
if [[ $(uname -m) != "arm64" ]]; then
    echo "❌ Error: Whispr requires Apple Silicon (M1/M2/M3/M4)"
    echo "   MLX Whisper only runs on Apple Silicon Macs."
    exit 1
fi

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    echo "📦 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add to path for this session
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Install ffmpeg
if ! command -v ffmpeg &> /dev/null; then
    echo "📦 Installing ffmpeg..."
    brew install ffmpeg
else
    echo "✓ ffmpeg already installed"
fi

# Install pipx if needed
if ! command -v pipx &> /dev/null; then
    echo "📦 Installing pipx..."
    brew install pipx
    pipx ensurepath
fi

# Install mlx-whisper
if ! command -v mlx_whisper &> /dev/null; then
    echo "📦 Installing mlx-whisper..."
    pipx install mlx-whisper
else
    echo "✓ mlx-whisper already installed"
fi

# Verify installations
echo ""
echo "Verifying installations..."

if command -v ffmpeg &> /dev/null && command -v mlx_whisper &> /dev/null; then
    echo ""
    echo "✅ All dependencies installed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Add this to your ~/.hammerspoon/init.lua:"
    echo ""
    echo '   hs.loadSpoon("WhisprByTheo")'
    echo '   spoon.WhisprByTheo:start()'
    echo ""
    echo "2. Reload Hammerspoon config"
    echo "3. Press the key you want to use when prompted"
    echo ""
    echo "🎉 You're all set!"
else
    echo ""
    echo "❌ Something went wrong. Please check the errors above."
    exit 1
fi
