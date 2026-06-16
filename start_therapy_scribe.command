#!/bin/bash

# ─────────────────────────────────────────────────────────────
# TherapyNote AI Scribe — Robust Launcher
# ─────────────────────────────────────────────────────────────

# 1. Absolute Path Normalization
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OLLAMA_PORT=11434
OLLAMA_URL="http://localhost:$OLLAMA_PORT"
LOG_DIR="$HOME/Library/Logs/TherapyNoteScribe"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/ollama.log"

# Log session start
echo "[$(date)] Starting TherapyNote AI Scribe Launcher" >> "$LOG_FILE"

# 2. Hide Terminal window (Mac only)
osascript -e 'tell application "System Events" to set visible of process "Terminal" to false' 2>/dev/null &

# 3. Helper: show a popup
error_popup() {
  echo "[$(date)] ERROR: $1" >> "$LOG_FILE"
  osascript -e "display dialog \"$1\" buttons {\"OK\"} default button \"OK\" with icon stop with title \"TherapyNote AI Scribe\""
}

# 4. Layered Binary Discovery
find_ollama() {
    # Strategy A: Check current PATH
    local bin=$(command -v ollama 2>/dev/null)
    if [ -n "$bin" ]; then echo "$bin"; return 0; fi

    # Strategy B: Check common absolute paths
    local common_paths=("/usr/local/bin/ollama" "/opt/homebrew/bin/ollama" "/usr/bin/ollama" "/bin/ollama")
    for path in "${common_paths[@]}"; do
        if [ -f "$path" ]; then echo "$path"; return 0; fi
    done

    # Strategy C: Check Ollama.app bundle
    if [ -d "/Applications/Ollama.app" ]; then
        local bundle_bin=$(find /Applications/Ollama.app -name "ollama" -type f | head -n 1)
        if [ -n "$bundle_bin" ]; then echo "$bundle_bin"; return 0; fi
    fi

    return 1
}

OLLAMA_BIN=$(find_ollama)

if [ -z "$OLLAMA_BIN" ]; then
    error_popup "Ollama binary not found.\n\nPlease ensure Ollama is installed from https://ollama.com/download"
    exit 1
fi

echo "[$(date)] Using Ollama binary: $OLLAMA_BIN" >> "$LOG_FILE"

# 5. Force Environment Variables (CORS Fix)
# Use launchctl for the system session and export for the local process
launchctl setenv OLLAMA_ORIGINS "*"
export OLLAMA_ORIGINS="*"

# 6. Process Management
# Kill existing Ollama to ensure the new CORS settings are applied
pkill -f ollama || true
sleep 2

# 7. Start Ollama
echo "[$(date)] Starting Ollama server..." >> "$LOG_FILE"
"$OLLAMA_BIN" serve > "$LOG_FILE" 2>&1 &
OLLAMA_PID=$!

# 8. Readiness Check
WAITED=0
MAX_WAIT=30
while ! curl -s --max-time 2 "$OLLAMA_URL/api/tags" > /dev/null 2>&1; do
    sleep 1
    WAITED=$((WAITED + 1))
    if [ $WAITED -ge $MAX_WAIT ]; then
        error_popup "Ollama took too long to start.\n\nPlease check if llama3 is installed: 'ollama pull llama3'"
        exit 1
    fi
done

echo "[$(date)] Ollama is ready." >> "$LOG_FILE"

# 9. Launch Chrome
open "$SCRIPT_DIR/popup.html"
sleep 1
osascript -e 'tell application "Google Chrome" to activate' 2>/dev/null

# Keep process alive
wait $OLLAMA_PID 2>/dev/null
