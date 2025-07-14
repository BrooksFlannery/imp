#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <number_of_agents>"
  exit 1
fi

N=$1

# Build AppleScript dynamically
APPLE_SCRIPT="tell application \"Cursor\" to activate
delay 0.1
tell application \"System Events\"\n"

# First agent: focus input, open tab, type prompt, enter
APPLE_SCRIPT+="  keystroke \"l\" using {command down}\n"
APPLE_SCRIPT+="  delay 0.2\n"
APPLE_SCRIPT+="  keystroke \"t\" using {command down}\n"
APPLE_SCRIPT+="  delay 0.2\n"
APPLE_SCRIPT+="  keystroke \"Agent 1 reporting in! My id is 1.\"\n"
APPLE_SCRIPT+="  keystroke return\n"
APPLE_SCRIPT+="  delay 0.2\n"

# Subsequent agents
for ((i=2; i<=N; i++)); do
  APPLE_SCRIPT+="  keystroke \"t\" using {command down}\n"
  APPLE_SCRIPT+="  delay 0.2\n"
  APPLE_SCRIPT+="  keystroke \"Agent $i reporting in! My id is $i.\"\n"
  APPLE_SCRIPT+="  keystroke return\n"
  APPLE_SCRIPT+="  delay 0.2\n"
done

APPLE_SCRIPT+="end tell\n"

# Run the AppleScript
echo -e "$APPLE_SCRIPT" | osascript -
