#!/usr/bin/env bash

# IMP Finish Script
# - Takes a phase name and path as arguments
# - Updates the phase status from any state to complete in imp-plan.md

set -e

usage() {
  echo "Usage: $0 <phase-name> <imp-plan-path>"
  echo "Example: $0 'Phase 1: Project Setup and Infrastructure' .imp/imp-mock-spec/imp-plan.md"
  echo "Example: $0 'Phase 1: Project Setup and Infrastructure' .imp/imp-mock-spec"
  echo ""
  echo "This script will:"
  echo "  1. Use the provided path to find imp-plan.md"
  echo "  2. Update the specified phase status to complete"
  echo "  3. Fail loudly if phase not found or already complete"
  exit 1
}

# Function to resolve imp-plan.md path
resolve_plan_path() {
    local path="$1"
    local plan_file
    
    # If path is a directory, look for imp-plan.md inside it
    if [ -d "$path" ]; then
        plan_file="$path/imp-plan.md"
    # If path is already a file, use it directly
    elif [ -f "$path" ]; then
        plan_file="$path"
    else
        echo "Error: Path '$path' is not a valid directory or file" >&2
        exit 1
    fi
    
    # Verify the plan file exists
    if [ ! -f "$plan_file" ]; then
        echo "Error: imp-plan.md not found at '$plan_file'" >&2
        exit 1
    fi
    
    echo "$plan_file"
}

# Function to update phase status in Mermaid diagram
update_phase_status() {
    local plan_file="$1"
    local phase_name="$2"
    local temp_file
    
    temp_file=$(mktemp)
    
    # Check if phase exists and get current status
    local phase_line
    local current_status
    
    phase_line=$(grep -n "\[$phase_name\]" "$plan_file" || true)
    
    if [ -z "$phase_line" ]; then
        echo "Error: Phase '$phase_name' not found in $plan_file" >&2
        exit 1
    fi
    
    # Extract current status
    current_status=$(echo "$phase_line" | sed -E 's/.*:::(.*)$/\1/')
    
    if [ "$current_status" = "complete" ]; then
        echo "Error: Phase '$phase_name' is already marked as complete" >&2
        exit 1
    fi
    
    if [ "$current_status" != "inProgress" ]; then
        echo "Warning: Phase '$phase_name' is in state '$current_status', not 'inProgress'. Forcing to 'complete'." >&2
    fi
    
    # Update the status to complete (from any state except already complete)
    sed -E "s/\[$phase_name\]:::(incomplete|inProgress|failed)/\[$phase_name\]:::complete/g" "$plan_file" > "$temp_file"
    
    # Verify the change was made
    if ! grep -q "\[$phase_name\]:::complete" "$temp_file"; then
        echo "Error: Failed to update phase status in $plan_file" >&2
        rm -f "$temp_file"
        exit 1
    fi
    
    # Replace original file
    mv "$temp_file" "$plan_file"
    
    echo "✓ Updated phase '$phase_name' status to complete"
}

main() {
    if [ $# -ne 2 ]; then
        usage
    fi
    
    local phase_name="$1"
    local imp_path="$2"
    
    # Resolve the imp-plan.md path
    echo "Resolving imp-plan.md path..."
    local plan_file
    plan_file=$(resolve_plan_path "$imp_path")
    echo "Using plan file: $plan_file"
    
    echo "Updating phase status in: $plan_file"
    echo "Phase: $phase_name"
    echo ""
    
    # Update the phase status
    update_phase_status "$plan_file" "$phase_name"
    
    echo ""
    echo "✓ Phase completion recorded successfully"
    
    # Call imp-spawner.sh to spawn agents for newly eligible phases
    echo ""
    echo "Checking for newly eligible phases..."
    # Get IMP directory (where this script is located)
    IMP_DIR=$(dirname "$(realpath "$0")")
    "$IMP_DIR/imp-spawner.sh" "$plan_file"
}

main "$@" 