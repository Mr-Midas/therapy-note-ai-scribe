#!/bin/bash
# ─────────────────────────────────────────────────────────────
# TherapyNote AI Scribe — Launcher
# Double-click this file to start everything.
# ─────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OLLAMA_PORT=11434
OLLAMA_URL="http://localhost:$OLLAMA_PORT"
LOG_DIR="$HOME/Library/Logs/TherapyNoteScribe"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/ollama.log"

# ── Hide Terminal window ──────────────────────────────────────
osascript -e 'tell application "System Events" to set visible of process "Terminal" to false' 2>/dev/null &

# ── Helper: show a popup if something goes wrong ──────────────
error_popup() {
  osascript -e "display dialog \"$1\" buttons {\"OK\"} default button \"OK\" with icon stop with title \"TherapyNote AI Scribe\""
}

# ── Check and Reset Ollama ──────────────────────────────────
# 1. Try to find the ollama binary in common locations
OLLAMA_BIN=""
for path in "/usr/local/bin/ollama" "/opt/homebrew/bin/ollama" "/usr/bin/ollama" "/bin/ollama"; do
    if [ -f "$path" ]; then
        OLLAMA_BIN="$path"
        break
    fi
done

# 2. Fallback: check if it's inside the Ollama.app bundle
if [ -z "$OLLAMA_BIN" ] && [ -d "/Applications/Ollama.app" ]; then
    # Search for the binary inside the app bundle
    FOUND_BIN=$(find /Applications/Ollama.app -name "ollama" -type f | head -n 1)
    if [ -n "$FOUND_BIN" ]; then
        OLLAMA_BIN="$FOUND_BIN"
    fi
fi

# 3. If still not found, show error
if [ -z "$OLLAMA_BIN" ]; then
    error_popup "Ollama binary not found.\n\nPlease make sure you have installed Ollama from https://ollama.com/download"
    exit 1
fi

# We kill any existing ollama process to ensure it starts with OLLAMA_ORIGINS="*"
# This prevents the 403 Forbidden error in Chrome Extensions.
pkill -f ollama || true
sleep 2

# Start Ollama with CORS permissions enabled
export OLLAMA_ORIGINS="*"
"$OLLAMA_BIN" serve > "$LOG_FILE" 2>&1 &
OLLAMA_PID=$!

# ── Wait for Ollama to be ready (up to 30 seconds) ───────────
WAITED=0
MAX_WAIT=30
echo "Starting Ollama..." > "$LOG_FILE.status"

while ! check_ollama; do
  sleep 1
  WAITED=$((WAITED + 1))
  if [ $WAITED -ge $MAX_WAIT ]; then
    error_popup "Ollama took too long to start.\n\nPlease check that llama3 is installed by opening Terminal and running: ollama pull llama3"
    exit 1
  fi
done

# ── Ollama is ready — open the extension in Chrome ────────────
open "$SCRIPT_DIR/popup.html"

sleep 1
osascript -e 'tell application "Google Chrome" to activate' 2>/dev/null

# ── Keep the script alive so Ollama stays running ─────────────
# When the user closes this, Ollama will also stop.
# This is by design — no background processes left behind.
wait $OLLAMA_PID 2>/dev/null
