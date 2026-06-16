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

-- Build shell script safely line-by-line to prevent compiler/copy-paste errors
set sh to "APP_PATH=" & quoted form of appPath & linefeed
set sh to sh & "CMD_FILE=" & quoted form of commandFile & linefeed
set sh to sh & "mkdir -p \"$APP_PATH/Contents/MacOS\"" & linefeed
set sh to sh & "mkdir -p \"$APP_PATH/Contents/Resources\"" & linefeed
set sh to sh & "cp \"$CMD_FILE\" \"$APP_PATH/Contents/Resources/start_therapy_scribe.command\"" & linefeed

set sh to sh & "cat > \"$APP_PATH/Contents/Info.plist\" << 'EOF'" & linefeed
set sh to sh & "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" & linefeed
set sh to sh & "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">" & linefeed
set sh to sh & "<plist version=\"1.0\">" & linefeed
set sh to sh & "<dict>" & linefeed
set sh to sh & "<key>CFBundleExecutable</key><string>launcher</string>" & linefeed
set sh to sh & "<key>CFBundleName</key><string>TherapyNote AI Scribe</string>" & linefeed
set sh to sh & "<key>CFBundleDisplayName</key><string>TherapyNote AI Scribe</string>" & linefeed
set sh to sh & "<key>CFBundleIdentifier</key><string>com.therapynote.ai-scribe</string>" & linefeed
set sh to sh & "<key>CFBundleVersion</key><string>1.0</string>" & linefeed
set sh to sh & "<key>CFBundlePackageType</key><string>APPL</string>" & linefeed
set sh to sh & "<key>LSMinimumSystemVersion</key><string>11.0</string>" & linefeed
set sh to sh & "<key>LSUIElement</key><false/>" & linefeed
set sh to sh & "</dict>" & linefeed
set sh to sh & "</plist>" & linefeed
set sh to sh & "EOF" & linefeed

set sh to sh & "cat > \"$APP_PATH/Contents/MacOS/launcher\" << 'EOF'" & linefeed
set sh to sh & "#!/bin/bash" & linefeed
set sh to sh & "SCRIPT_DIR=\"$(cd \"$(dirname \"$0\")/../Resources\" && pwd)\"" & linefeed
set sh to sh & "exec bash \"$SCRIPT_DIR/start_therapy_scribe.command\"" & linefeed
set sh to sh & "EOF" & linefeed

set sh to sh & "chmod +x \"$APP_PATH/Contents/MacOS/launcher\"" & linefeed

do shell script sh

-- Success Message
display dialog "TherapyNote AI Scribe app created on your Desktop!" buttons {"OK"} default button 1 with title "Setup Complete"

-- Try to add to Dock
try
	do shell script "defaults write com.apple.dock persistent-apps -array-add '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>file:///Users/$(whoami)/Desktop/TherapyNote%20AI%20Scribe.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>'; killall Dock"
end try