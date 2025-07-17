#!/bin/bash

# IMP (Implementation Management Platform) - Plan Generation Agent
# Spawns a Cursor agent to generate implementation plan and Mermaid diagram

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[IMP]${NC} $1"
}

error() {
    echo -e "${RED}[IMP ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[IMP SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[IMP WARNING]${NC} $1"
}

# Help function
show_help() {
    echo "Usage: $0 <spec-directory>"
    echo ""
    echo "Spawns a Cursor agent to generate implementation plan and Mermaid diagram."
    echo ""
    echo "Arguments:"
    echo "  spec-directory    Path to the IMP spec directory (e.g., .imp/imp-specname)"
    echo ""
    echo "Examples:"
    echo "  $0 .imp/imp-my-feature"
    echo "  $0 .imp/imp-api-integration"
}

# Validate arguments
if [ $# -eq 0 ]; then
    error "No spec directory provided"
    show_help
    exit 1
fi

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

SPEC_DIR="$1"

# Validate spec directory exists
if [ ! -d "$SPEC_DIR" ]; then
    error "Spec directory not found: $SPEC_DIR"
    exit 1
fi

# Check if config.json exists
CONFIG_FILE="$SPEC_DIR/config.json"
if [ ! -f "$CONFIG_FILE" ]; then
    error "Config file not found: $CONFIG_FILE"
    exit 1
fi

# Read spec file path from config
SPEC_FILE=$(jq -r '.spec_file' "$CONFIG_FILE")
if [ "$SPEC_FILE" = "null" ] || [ -z "$SPEC_FILE" ]; then
    error "Could not read spec_file from config: $CONFIG_FILE"
    exit 1
fi

# Validate spec file still exists
if [ ! -f "$SPEC_FILE" ]; then
    error "Spec file not found: $SPEC_FILE"
    exit 1
fi

log "Starting plan generation for: $SPEC_FILE"

# Define output file paths
ANALYSIS_JSON_FILE="$SPEC_DIR/analysis.json"
MERMAID_FILE="$SPEC_DIR/imp-plan.md"
PHASES_DIR="$SPEC_DIR/phases"

log "Output files:"
log "  JSON Plan: $ANALYSIS_JSON_FILE"
log "  Mermaid: $MERMAID_FILE"
log "  Phase Files: $PHASES_DIR"

# Use the existing plan generation prompt file
# Get IMP directory (where this script is located)
IMP_DIR=$(dirname "$(realpath "$0")")
PLAN_GENERATION_PROMPT_FILE="$IMP_DIR/imp-plan-prompt.txt"
if [ ! -f "$PLAN_GENERATION_PROMPT_FILE" ]; then
    error "Plan generation prompt file not found: $PLAN_GENERATION_PROMPT_FILE"
    exit 1
fi

log "Using plan generation prompt file: $PLAN_GENERATION_PROMPT_FILE"

# Replace placeholders in the prompt
PLAN_GENERATION_PROMPT=$(cat "$PLAN_GENERATION_PROMPT_FILE" | \
    sed "s|{SPEC_FILE}|$SPEC_FILE|g" | \
    sed "s|{ANALYSIS_JSON_FILE}|$ANALYSIS_JSON_FILE|g" | \
    sed "s|{MERMAID_FILE}|$MERMAID_FILE|g" | \
    sed "s|{PHASES_DIR}|$PHASES_DIR|g")

# Copy the prompt to clipboard
echo "$PLAN_GENERATION_PROMPT" | pbcopy
log "Plan generation prompt copied to clipboard"

# Spawn Cursor agent using AppleScript
log "Spawning Cursor agent for plan generation..."

# Activate Cursor
osascript -e 'tell application "Cursor" to activate' 2>/dev/null || log "Warning: Could not activate Cursor"

# Create new chat and paste the prompt
osascript << EOF
tell application "System Events"
  # Open new chat (Cmd+L)
  keystroke "l" using {command down}
  delay 0.5
  
  # Create new tab (Cmd+T)
  keystroke "t" using {command down}
  delay 0.5
  
  # Paste the prompt
  keystroke "v" using {command down}
  delay 0.2
  
  # Send the prompt
  keystroke return
  delay 0.2
end tell
EOF

success "Cursor agent spawned for plan generation"
log "Agent prompt sent to Cursor"
log "Please paste the prompt and let the agent generate the files"
log "Files will be created at:"
log "  - $ANALYSIS_JSON_FILE"
log "  - $MERMAID_FILE"
log "  - Phase files in: $PHASES_DIR"

exit 0 