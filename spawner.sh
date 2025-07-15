#!/bin/bash

# This script spawns multiple implementation agents by:
# 1. Reading a prompt template
# 2. Substituting variables for each phase
# 3. Setting the clipboard with the agent prompt
# 4. Using AppleScript to automate Cursor:
#    - Open new chat tabs
#    - Focus the input field
#    - Paste the agent prompt
#    - Submit the prompt

# Check if we have the required arguments
if [ -z "$1" ]; then
  echo "Usage: $0 <spec_file_name> <phase_name1> [phase_name2] [phase_name3] ..."
  echo "Example: $0 'test-spec.mdx' 'Phase 2a: User Guide Generation' 'Phase 2b: Technical Specification Generation'"
  echo "Or use automatic phase detection: $0 'test-spec.mdx'"
  exit 1
fi

# Store the spec file name (first argument)
SPEC_NAME="$1"
shift  # Remove the first argument, leaving only phase names

# Check if spec file exists
if [ ! -f "$SPEC_NAME" ]; then
  echo "Error: Spec file '$SPEC_NAME' not found" >&2
  exit 1
fi

# Set up logging to track what's happening
LOG_FILE="spawner.log"
echo "--- $(date) ---" >> "$LOG_FILE"
echo "[spawner] Starting spawner.sh with spec: $SPEC_NAME" | tee -a "$LOG_FILE"

# If no phase names provided, use phase-analyzer.sh to get them automatically
if [ $# -eq 0 ]; then
  echo "[spawner] No phases provided, using phase-analyzer.sh to detect phases..." | tee -a "$LOG_FILE"
  
  # Check if phase-analyzer.sh exists
  if [ ! -f "./phase-analyzer.sh" ]; then
    echo "Error: phase-analyzer.sh not found in current directory" >&2
    exit 1
  fi
  
  # Run phase-analyzer.sh and capture its output
  PHASES_FROM_ANALYZER=$(./phase-analyzer.sh "$SPEC_NAME")
  ANALYZER_EXIT_CODE=$?
  
  if [ $ANALYZER_EXIT_CODE -eq 1 ]; then
    echo "All phases are complete. Nothing to spawn." | tee -a "$LOG_FILE"
    exit 0
  elif [ $ANALYZER_EXIT_CODE -ne 0 ]; then
    echo "Error: phase-analyzer.sh failed with exit code $ANALYZER_EXIT_CODE" >&2
    exit $ANALYZER_EXIT_CODE
  fi
  
  # Convert the quoted phase names to arguments
  eval "set -- $PHASES_FROM_ANALYZER"
  echo "[spawner] Detected phases: $@" | tee -a "$LOG_FILE"
fi

echo "[spawner] Final phases to spawn: $@" | tee -a "$LOG_FILE"

# Read the prompt template that will be customized for each agent
echo "[spawner] Reading implementation_agent_prompt.txt..." | tee -a "$LOG_FILE"
PROMPT_TEMPLATE=$(cat implementation_agent_prompt.txt)

# Activate Cursor first
echo "[spawner] Activating Cursor..." | tee -a "$LOG_FILE"
osascript -e 'tell application "Cursor" to activate' 2>&1 | tee -a "$LOG_FILE"
sleep 0.5

echo "[spawner] Looping through phases..." | tee -a "$LOG_FILE"
# For each phase, we'll create a new tab and spawn an agent
for PHASE_NAME in "$@"; do
  echo "[spawner] Setting up phase: $PHASE_NAME" | tee -a "$LOG_FILE"
  
  # Replace the placeholder variables in the prompt template with actual values
  # {SPEC_NAME} becomes the actual spec file name
  # {PHASE_NAME} becomes the current phase name
  AGENT_PROMPT=$(echo "$PROMPT_TEMPLATE" | sed "s/{SPEC_NAME}/$SPEC_NAME/g" | sed "s/{PHASE_NAME}/$PHASE_NAME/g")

  # Copy the customized prompt to the system clipboard
  # pbcopy is macOS's clipboard command
  echo "$AGENT_PROMPT" | pbcopy
  echo "[spawner] Clipboard set for phase: $PHASE_NAME" | tee -a "$LOG_FILE"
  
  # Log what's actually in the clipboard for debugging
  echo "[spawner] Clipboard contents for $PHASE_NAME:" >> "$LOG_FILE"
  pbpaste >> "$LOG_FILE"

  # Build AppleScript for this specific phase
  if [ "$PHASE_NAME" = "$1" ]; then
    # First phase: new chat + new tab
    echo "[spawner] First phase detected - using Cmd+L then Cmd+T" | tee -a "$LOG_FILE"
    PHASE_SCRIPT="tell application \"System Events\"
  keystroke \"l\" using {command down}
  delay 0.5
  keystroke \"t\" using {command down}
  delay 0.5
  keystroke \"v\" using {command down}
  delay 0.2
  keystroke return
  delay 0.2
end tell"
  else
    # Subsequent phases: just new tab
    echo "[spawner] Subsequent phase - using Cmd+T only" | tee -a "$LOG_FILE"
    PHASE_SCRIPT="tell application \"System Events\"
  keystroke \"t\" using {command down}
  delay 0.5
  keystroke \"v\" using {command down}
  delay 0.2
  keystroke return
  delay 0.2
end tell"
  fi
  
  # Execute the AppleScript for this phase immediately
  echo "[spawner] Executing AppleScript for phase: $PHASE_NAME" | tee -a "$LOG_FILE"
  echo -e "$PHASE_SCRIPT" | osascript - 2>&1 | tee -a "$LOG_FILE"
  
  # Brief pause between phases
  sleep 0.5
done

echo "[spawner] All phases spawned successfully." | tee -a "$LOG_FILE"
