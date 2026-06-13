-- ─────────────────────────────────────────────────────────────
-- TherapyNote AI Scribe — App Generator
-- Double-click this ONCE to create the desktop app.
-- After that, use "TherapyNote AI Scribe.app" instead.
-- ─────────────────────────────────────────────────────────────

set scriptDir to do shell script "dirname \"$0\""
set commandFile to scriptDir & "/start_therapy_scribe.command"
set appPath to (path to desktop folder as text) & "TherapyNote AI Scribe.app"

-- Verify the .command file exists
tell application "System Events"
	if not (exists file commandFile) then
		display dialog "Cannot find start_therapy_scribe.command in the same folder." buttons {"OK"} default button "OK" with icon stop with title "Setup Error"
		return
	end if
end tell

-- Remove old version if it exists
tell application "System Events"
	if (exists folder appPath) then
		do shell script "rm -rf " & quoted form of (POSIX path of appPath)
	end if
end tell

-- Create the .app bundle structure
do shell script "
APP_PATH=" & quoted form of (POSIX path of appPath) & "
mkdir -p \"$APP_PATH/Contents/MacOS\"
mkdir -p \"$APP_PATH/Contents/Resources\"

# Write Info.plist
cat > \"$APP_PATH/Contents/Info.plist\" << 'PLIST'
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
    <key>CFBundleExecutable</key>
    <string>launcher</string>
    <key>CFBundleName</key>
    <string>TherapyNote AI Scribe</string>
    <key>CFBundleDisplayName</key>
    <string>TherapyNote AI Scribe</string>
    <key>CFBundleIdentifier</key>
    <string>com.therapynote.ai-scribe</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>11.0</string>
    <key>LSUIElement</key>
    <false/>
</dict>
</plist>
PLIST

# Write the launcher shell script
cat > \"$APP_PATH/Contents/MacOS/launcher\" << 'LAUNCHER'
#!/bin/bash
SCRIPT_DIR=\"$(cd \"$(dirname \"\$0\")/../..\" && pwd)\"
exec bash \"\$SCRIPT_DIR/start_therapy_scribe.command\"
LAUNCHER

chmod +x \"$APP_PATH/Contents/MacOS/launcher\"
"

-- Make the .command file executable
do shell script "chmod +x " & quoted form of commandFile

-- Ask if user wants to pin to Dock
display dialog "TherapyNote AI Scribe.app has been created on your Desktop!

You can drag it to your Dock for easy access." buttons {"OK"} default button "OK" with title "Setup Complete" with note

-- Try to add to Dock
try
	do shell script "
defaults write com.apple.dock persistent-apps -array-add '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>file:///Users/$(whoami)/Desktop/TherapyNote%20AI%20Scribe.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>'
killall Dock
"
end try
