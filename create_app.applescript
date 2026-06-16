set appName to "TherapyNote AI Scribe.app"
set appPath to POSIX path of (path to desktop folder) & appName
set scriptPath to POSIX path of (path to me)
set scriptDir to do shell script "dirname " & quoted form of scriptPath
set commandFile to scriptDir & "/start_therapy_scribe.command"

-- Verify .command exists
tell application "System Events"
	if not (exists file commandFile) then
		display dialog "Cannot find start_therapy_scribe.command" buttons {"OK"} default button 1 with icon stop with title "Error"
		return
	end if
end tell

-- Remove old app if exists
do shell script "rm -rf " & quoted form of appPath

-- Create app bundle directories
do shell script "mkdir -p " & quoted form of appPath & "/Contents/MacOS " & quoted form of appPath & "/Contents/Resources"

-- Copy .command into app bundle
do shell script "cp " & quoted form of commandFile & " " & quoted form of appPath & "/Contents/Resources/start_therapy_scribe.command"

-- Write Info.plist
do shell script "cat > " & quoted form of appPath & "/Contents/Info.plist << 'EOF'
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
EOF"

-- Write launcher
do shell script "cat > " & quoted form of appPath & "/Contents/MacOS/launcher << 'EOF'
#!/bin/bash
SCRIPT_DIR=\"$(cd \"$(dirname \"$0\")/../Resources\" && pwd)\"
exec bash \"$SCRIPT_DIR/start_therapy_scribe.command\"
EOF"

-- Make launcher executable
do shell script "chmod +x " & quoted form of appPath & "/Contents/MacOS/launcher"

-- Success Message
display dialog "TherapyNote AI Scribe app created on your Desktop!" buttons {"OK"} default button 1 with title "Setup Complete"

-- Try to add to Dock
try
	do shell script "defaults write com.apple.dock persistent-apps -array-add '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>file:///Users/$(whoami)/Desktop/TherapyNote%20AI%20Scribe.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>'; killall Dock"
end try