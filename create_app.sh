#!/bin/bash

# TherapyNote AI Scribe — App Generator (Bash Version)
# This script creates the .app bundle on your Desktop.

# 1. Setup Paths
APP_NAME="TherapyNote AI Scribe.app"
DESKTOP_PATH="$HOME/Desktop"
APP_PATH="$DESKTOP_PATH/$APP_NAME"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMMAND_FILE="$SCRIPT_DIR/start_therapy_scribe.command"

echo "🚀 Starting App Generation..."

# -----------------------------------------------------------------
# PRE-FLIGHT CHECK: Verify Ollama is actually installed on this Mac
# -----------------------------------------------------------------
echo "🔍 Verifying Ollama installation..."
OLLAMA_FOUND=false
# Check common paths
for path in "/usr/local/bin/ollama" "/opt/homebrew/bin/ollama" "/usr/bin/ollama" "/bin/ollama"; do
    if [ -f "$path" ]; then OLLAMA_FOUND=true; break; fi
done

# Check App bundle
if [ "$OLLAMA_FOUND" = false ] && [ -d "/Applications/Ollama.app" ]; then
    if [ -n "$(find /Applications/Ollama.app -name "ollama" -type f | head -n 1)" ]; then
        OLLAMA_FOUND=true
    fi
fi

if [ "$OLLAMA_FOUND" = false ]; then
    osascript -e "display dialog \"Pre-flight check failed: Ollama binary not found on this system.\n\nPlease install Ollama from https://ollama.com/download before creating the app.\" buttons {\"OK\"} default button 1 with icon stop with title \"Installation Error\""
    echo "❌ Error: Ollama not found. Aborting app creation."
    exit 1
fi
echo "✅ Ollama found. Proceeding..."
# -----------------------------------------------------------------

# 2. Verify .command exists
if [ ! -f "$COMMAND_FILE" ]; then
    osascript -e "display dialog \"Cannot find start_therapy_scribe.command in $SCRIPT_DIR\" buttons {\"OK\"} default button 1 with icon stop with title \"Error\""
    exit 1
fi

# 3. Remove old app if it exists
if [ -d "$APP_PATH" ]; then
    echo "Removing old version..."
    rm -rf "$APP_PATH"
fi

# 4. Create App Bundle Structure
echo "Creating bundle structure..."
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"

# 5. Copy the command file into Resources
echo "Copying command file..."
cp "$COMMAND_FILE" "$APP_PATH/Contents/Resources/start_therapy_scribe.command"

# 6. Create Info.plist
echo "Generating Info.plist..."
cat > "$APP_PATH/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>launcher</string>
    <key>CFBundleName</key><string>TherapyNote AI Scribe</string>
    <key>CFBundleDisplayName</key><string>TherapyNote AI Scribe</string>
    <key>CFBundleIdentifier</key><string>com.therapynote.ai-scribe</string>
    <key>CFBundleVersion</key><string>1.0</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>LSMinimumSystemVersion</key><string>11.0</string>
    <key>LSUIElement</key><false/>
</dict>
</plist>
EOF

# 7. Create Launcher
echo "Generating launcher..."
cat > "$APP_PATH/Contents/MacOS/launcher" << 'EOF'
#!/bin/bash
# Resolve the path to the Resources folder relative to the launcher
SCRIPT_DIR="$(cd "$(dirname "$0")/../Resources" && pwd)"
exec bash "$SCRIPT_DIR/start_therapy_scribe.command"
EOF

chmod +x "$APP_PATH/Contents/MacOS/launcher"

# 8. Success Message
osascript -e "display dialog \"TherapyNote AI Scribe.app created on your Desktop! \n\nDrag it to your Dock for easy access.\" buttons {\"OK\"} default button 1 with title \"Setup Complete\""

# 9. Try to add to Dock
echo "Attempting to add to Dock..."
defaults write com.apple.dock persistent-apps -array-add "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>file://$DESKTOP_PATH/$APP_NAME</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"
killall Dock

echo "✅ Done! You can now find the app on your Desktop."
