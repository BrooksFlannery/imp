#!/bin/bash

# IMP (Implementation Management Platform) - Initialization Script
# Phase 1: Basic Initialization
# Creates .imp directory structure and spawns spec analysis agent

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
    echo "Usage: $0 <spec-file-path>"
    echo ""
    echo "Creates IMP directory structure and initializes the implementation process."
    echo ""
    echo "Arguments:"
    echo "  spec-file-path    Path to the specification file to process"
    echo ""
    echo "Examples:"
    echo "  $0 my-feature-spec.md"
    echo "  $0 ./specs/api-integration.md"
}

# Validate arguments
if [ $# -eq 0 ]; then
    error "No specification file provided"
    show_help
    exit 1
fi

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

SPEC_FILE="$1"

# Validate spec file exists and is readable
if [ ! -f "$SPEC_FILE" ]; then
    error "Specification file not found: $SPEC_FILE"
    exit 1
fi

if [ ! -r "$SPEC_FILE" ]; then
    error "Specification file is not readable: $SPEC_FILE"
    exit 1
fi

log "Starting IMP initialization for spec: $SPEC_FILE"

# Get absolute path of spec file
SPEC_FILE_ABS=$(realpath "$SPEC_FILE")
log "Absolute path: $SPEC_FILE_ABS"

# Extract spec name from filename (remove extension and path)
SPEC_NAME=$(basename "$SPEC_FILE" | sed 's/\.[^.]*$//')
log "Spec name: $SPEC_NAME"

# Create .imp directory if it doesn't exist
IMP_DIR=".imp"
if [ ! -d "$IMP_DIR" ]; then
    log "Creating .imp directory"
    mkdir -p "$IMP_DIR"
    success "Created .imp directory"
else
    log ".imp directory already exists"
fi

# Create imp-specname subdirectory
SPEC_DIR="$IMP_DIR/imp-$SPEC_NAME"
if [ ! -d "$SPEC_DIR" ]; then
    log "Creating spec directory: $SPEC_DIR"
    mkdir -p "$SPEC_DIR"
    success "Created spec directory: $SPEC_DIR"
else
    warning "Spec directory already exists: $SPEC_DIR"
fi

# Create basic directory structure
log "Creating basic directory structure"
mkdir -p "$SPEC_DIR/phases"
mkdir -p "$SPEC_DIR/logs"

# Store spec file path for future reference
echo "$SPEC_FILE_ABS" > "$SPEC_DIR/spec-path.txt"

# Create a basic configuration file
cat > "$SPEC_DIR/config.json" << EOF
{
  "spec_name": "$SPEC_NAME",
  "spec_file": "$SPEC_FILE_ABS",
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "imp_version": "0.2.0",
  "status": "initialized"
}
EOF

success "Created configuration file"

log "Phase 1 initialization complete"
success "Ready for spec analysis"

# Spawn plan generation agent
log "Spawning plan generation agent..."
# Get IMP directory (where this script is located)
IMP_DIR=$(dirname "$(realpath "$0")")
"$IMP_DIR/imp-plan.sh" "$SPEC_DIR"

success "Plan generation agent spawned"
log "The agent prompt has been copied to your clipboard"
log "Please paste it into Cursor and let the agent generate:"
log "  - $SPEC_DIR/analysis.json"
log "  - $SPEC_DIR/imp-plan.md"
log "  - Phase files in: $SPEC_DIR/phases"

exit 0 