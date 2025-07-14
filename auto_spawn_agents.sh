#!/bin/bash
osascript <<EOF
tell application "Cursor" to activate
delay 0.1
tell application "System Events"
  keystroke "l" using {command down}
  delay 0.2
  keystroke "t" using {command down}
  delay 0.2
  keystroke "FOCUS-TEST"
  keystroke return
end tell
EOF
