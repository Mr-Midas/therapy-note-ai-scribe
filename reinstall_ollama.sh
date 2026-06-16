#!/bin/bash

# Ollama Total Reset Script for macOS
# This script cleans up all Ollama installations to ensure a fresh start.

echo "🧹 Starting Ollama Total Reset..."

# 1. Kill all Ollama processes
echo "Stopping all Ollama processes..."
pkill -f ollama || echo "No Ollama processes running."
sleep 2

# 2. Remove the App bundle
if [ -d "/Applications/Ollama.app" ]; then
    echo "Removing /Applications/Ollama.app..."
    sudo rm -rf "/Applications/Ollama.app"
fi

# 3. Remove binaries from common paths
echo "Cleaning up binaries..."
sudo rm -f /usr/local/bin/ollama
sudo rm -f /opt/homebrew/bin/ollama
sudo rm -f /usr/bin/ollama

# 4. Remove config and logs
echo "Cleaning up config and logs..."
rm -rf ~/.ollama
rm -rf "$HOME/Library/Application Support/Ollama"
rm -rf "$HOME/Library/Logs/Ollama"

echo "------------------------------------------------------------"
echo "✅ Ollama has been completely removed from your system."
echo ""
echo "To reinstall properly:"
echo "1. Download Ollama from: https://ollama.com/download"
echo "2. Drag Ollama.app to your Applications folder"
echo "3. Launch Ollama.app and follow the setup (it will ask to install the CLI)"
echo "4. Run 'ollama pull llama3' in your terminal"
echo "------------------------------------------------------------"
echo "Once reinstalled, try the TherapyNote AI Scribe app again."
