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

-- Build shell script without heredocs (use printf to write files)
set sh to "APP_PATH=" & quoted form of appPath & linefeed
set sh to sh & "CMD_FILE=" & quoted form of commandFile & linefeed
set sh to sh & "mkdir -p \"$APP_PATH/Contents/MacOS\"" & linefeed
set sh to sh & "mkdir -p \"$APP_PATH/Contents/Resources\"" & linefeed
set sh to sh & "cp \"$CMD_FILE\" \"$APP_PATH/Contents/Resources/start_therapy_scribe.command\"" & linefeed

-- Write Info.plist using printf
set sh to sh & "printf '%s\\n' '<?xml version=\"1.0\" encoding=\"UTF-8\"?>' '<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">' '<plist version=\"1.0\">' '<dict>' '<key>CFBundleExecutable</key><string>launcher</string>' '<key>CFBundleName</key><string>TherapyNote AI Scribe</string>' '<key>CFBundleDisplayName</key><string>TherapyNote AI Scribe</string>' '<key>CFBundleIdentifier</key><string>com.therapynote.ai-scribe</string>' '<key>CFBundleVersion</key><string>1.0</string>' '<key>CFBundlePackageType</key><string>APPL</string>' '<key>LSMinimumSystemVersion</key><string>11.0</string>' '<key>LSUIElement</key><false/>' '</dict>' '</plist>' > \"$APP_PATH/Contents/Info.plist\"" & linefeed

-- Write launcher using printf
set sh to sh & "printf '%s\\n' '#!/bin/bash' 'SCRIPT_DIR=\"$(cd \"$(dirname \"$0\")/../Resources\" && pwd)\"' 'exec bash \"$SCRIPT_DIR/start_therapy_scribe.command\"' > \"$APP_PATH/Contents/MacOS/launcher\"" & linefeed

set sh to sh & "chmod +x \"$APP_PATH/Contents/MacOS/launcher\"" & linefeed

do shell script sh

-- Success Message
display dialog "TherapyNote AI Scribe app created on your Desktop!" buttons {"OK"} default button 1 with title "Setup Complete"

-- Try to add to Dock
try
	do shell script "defaults write com.apple.dock persistent-apps -array-add '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>file:///Users/$(whoami)/Desktop/TherapyNote%20AI%20Scribe.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>'; killall Dock"
end try