#!/bin/bash

# TherapyNote AI Scribe — Performance Diagnostic Tool
# Run this script while the extension is "Generating" a note.

echo "------------------------------------------------------------"
echo "🚀 TherapyNote AI Scribe Performance Diagnostics"
echo "------------------------------------------------------------"

# 1. Check if Ollama is running
if ! pgrep -x "ollama" > /dev/null; then
    echo "❌ Error: Ollama is not running. Please launch the app first."
    exit 1
fi
echo "✅ Ollama process found."

# 2. Check Memory Pressure
echo "🔍 Checking Memory Pressure..."
# vm_stat provides page-ins/outs. High 'page outs' = Swap = SLOW.
MEM_STAT=$(vm_stat)
echo "$MEM_STAT" | grep "page outs"
if [[ $(echo "$MEM_STAT" | grep "page outs" | awk '{print $3}') -gt 1000 ]]; then
    echo "⚠️ HIGH SWAP DETECTED: Your Mac is out of RAM. Close other apps (Chrome tabs, etc)."
else
    echo "✅ Memory pressure seems acceptable."
fi

# 3. Check CPU/GPU Usage
echo "🔍 Checking Resource Usage (Next 5 seconds)..."
echo "Wait... please trigger 'Generate' in the extension NOW!"
sleep 2
# Use 'top' to see if ollama is maxing out CPU
# On M1, high %CPU in top usually means it's running on CPU cores, not the Neural Engine/GPU
CPU_USAGE=$(top -l 1 -s 0 | grep "ollama" | awk '{print $9}')
if [ -z "$CPU_USAGE" ]; then
    echo "⚠️ Could not capture CPU usage. Is it still generating?"
else
    echo "📊 Current Ollama CPU Usage: $CPU_USAGE%"
    if (( $(echo "$CPU_USAGE > 100" | bc -l) )); then
        echo "⚠️ HIGH CPU usage detected. This often means it's NOT using the GPU/Metal."
    fi
fi

# 4. Inspect Logs for "Metal" or "CPU"
echo "🔍 Checking Ollama Logs for Hardware Acceleration..."
LOG_FILE="$HOME/Library/Logs/TherapyNoteScribe/ollama.log"
if [ -f "$LOG_FILE" ]; then
    # Search for Metal or GPU mentions in the log
    GPU_LOG=$(grep -Ei "metal|gpu|cuda|cpu" "$LOG_FILE" | tail -n 5)
    if [ -n "$GPU_LOG" ]; then
        echo "Log mentions: $GPU_LOG"
    else
        echo "No hardware info found in logs."
    fi
else
    echo "⚠️ Log file not found at $LOG_FILE"
fi

echo "------------------------------------------------------------"
echo "✅ Diagnostics complete. Please copy and paste this output to opencode."
