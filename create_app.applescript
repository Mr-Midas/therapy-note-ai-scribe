-- TherapyNote AI Scribe — App Generator
-- Double-click to create the desktop app on your Desktop.

set scriptPath to POSIX path of (path to me)
set scriptDir to do shell script "dirname " & quoted form of scriptPath
set commandFile to scriptDir & "/start_therapy_scribe.command"
set appPath to (path to desktop folder as text) & "TherapyNote AI Scribe.app"

-- Verify .command exists
tell application "System Events"
	if not (exists file commandFile) then
		display dialog "Cannot find start_therapy_scribe.command in the same folder." buttons {"OK"} default button "OK" with icon stop with title "Setup Error"
		return
	end if
end tell

-- Remove old app if exists
do shell script "rm -rf " & quoted form of (POSIX path of appPath)

-- Create app bundle using a separate shell script (avoids quoting hell)
set shellScript to "
APP_PATH=" & quoted form of (POSIX path of appPath) & "
COMMAND_FILE=" & quoted form of commandFile & "

mkdir -p \"$APP_PATH/Contents/MacOS\"
mkdir -p \"$APP_PATH/Contents/Resources\"

# Copy the command file into the app bundle so it is truly standalone
cp \"$COMMAND_FILE\" \"$APP_PATH/Contents/Resources/start_therapy_scribe.command\"

# Info.plist
cat > \"$APP_PATH/Contents/Info.plist\" << 'EOF'
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
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

# Launcher script
cat > \"$APP_PATH/Contents/MacOS/launcher\" << 'EOF'
#!/bin/bash
# Point the launcher to the Resources folder where the script was copied
SCRIPT_DIR=\"$(cd \"$(dirname \"$0\")/../Resources\" && pwd)\"
exec bash \"$SCRIPT_DIR/start_therapy_scribe.command\"
EOF

chmod +x \"$APP_PATH/Contents/MacOS/launcher\"
"

do shell script shellScript

-- Success (Syntax error resolved here)
display dialog "TherapyNote AI Scribe.app created on your Desktop!" & return & "Drag it to your Dock for easy access." buttons {"OK"} default button "OK" with title "Setup Complete"

-- Try to add to Dock
try
	do shell script "
defaults write com.apple.dock persistent-apps -array-add '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>file:///Users/$(whoami)/Desktop/TherapyNote%20AI%20Scribe.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>'
killall Dock
"
end try