#!/usr/bin/env bash

# IMP Spawner Script (Bash 3.2 compatible)
# - Parses imp-plan.md Mermaid diagram (edges define nodes)
# - Prints eligible phases (no dependencies or all dependencies complete)
# - Spawns Cursor agents for eligible phases

set -e

usage() {
  echo "Usage: $0 <imp-plan.md-file> [--list-only]"
  echo "Example: $0 .imp/imp-mock-spec/imp-plan.md"
  echo "Example: $0 .imp/imp-mock-spec/imp-plan.md --list-only"
  echo ""
  echo "Options:"
  echo "  --list-only    Only list eligible phases, don't spawn agents"
  exit 1
}

# Function to update phase status in Mermaid diagram
update_phase_status() {
    local plan_file="$1"
    local phase_name="$2"
    local new_status="$3"
    local temp_file
    
    temp_file=$(mktemp)
    
    # Check if phase exists and get current status
    local phase_line
    local current_status
    
    phase_line=$(grep -n "\[$phase_name\]" "$plan_file" || true)
    
    if [ -z "$phase_line" ]; then
        echo "Error: Phase '$phase_name' not found in $plan_file" >&2
        return 1
    fi
    
    # Extract current status
    current_status=$(echo "$phase_line" | sed -E 's/.*:::(.*)$/\1/')
    
    if [ "$current_status" = "$new_status" ]; then
        echo "Warning: Phase '$phase_name' is already in state '$new_status'" >&2
        return 0
    fi
    
    # Update the status
    sed -E "s/\[$phase_name\]:::(incomplete|inProgress|failed|complete)/\[$phase_name\]:::$new_status/g" "$plan_file" > "$temp_file"
    
    # Verify the change was made
    if ! grep -q "\[$phase_name\]:::$new_status" "$temp_file"; then
        echo "Error: Failed to update phase status in $plan_file" >&2
        rm -f "$temp_file"
        return 1
    fi
    
    # Replace original file
    mv "$temp_file" "$plan_file"
    
    echo "✓ Updated phase '$phase_name' status to $new_status"
}

# Function to spawn a Cursor agent for a phase
spawn_agent() {
    local phase_id="$1"
    local phase_label="$2"
    local spec_name="$3"
    local imp_dir="$4"
    local plan_file="$5"
    
    echo "Spawning agent for: $phase_label"
    
    # Update phase status to inProgress
    echo "Updating phase status to inProgress..."
    if ! update_phase_status "$plan_file" "$phase_label" "inProgress"; then
        echo "Error: Failed to update phase status" >&2
        return 1
    fi
    
    # Read the prompt template
    # Get IMP directory (where this script is located)
    IMP_DIR=$(dirname "$(realpath "$0")")
    if [ ! -f "$IMP_DIR/imp-agent.prompt" ]; then
        echo "Error: imp-agent.prompt not found at $IMP_DIR/imp-agent.prompt" >&2
        return 1
    fi
    
    local prompt_template=$(cat "$IMP_DIR/imp-agent.prompt")
    
    # Generate phase filename (convert phase label to filename format)
    # Extract phase number from phase_id (e.g., Phase1 -> 1)
    local phase_num=$(echo "$phase_id" | sed 's/Phase//')
    # Extract title from phase label (e.g., "Phase 1: Project Setup and Infrastructure" -> "project-setup-and-infrastructure")
    local title=$(echo "$phase_label" | sed 's/^Phase [0-9]*: //' | sed 's/[^a-zA-Z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//' | tr '[:upper:]' '[:lower:]')
    phase_file="phase-${phase_num}-${title}.md"
    
    # Substitute variables in the prompt
    local prompt=$(echo "$prompt_template" | \
        sed "s/{PHASE_NAME}/$phase_label/g" | \
        sed "s/{SPEC_NAME}/$spec_name/g" | \
        sed "s/{IMP_DIR}/$imp_dir/g" | \
        sed "s/{PHASE_FILE}/$phase_file/g")

    # Copy prompt to clipboard
    echo "$prompt" | pbcopy
    
    # Activate Cursor and create new tab
    osascript -e 'tell application "Cursor" to activate' >/dev/null 2>&1
    sleep 0.5
    
    # Create new tab and paste prompt
    osascript -e 'tell application "System Events"
  keystroke "t" using {command down}
  delay 0.5
  keystroke "v" using {command down}
  delay 0.2
  keystroke return
  delay 0.2
end tell' >/dev/null 2>&1
    
    echo "  ✓ Agent spawned in new Cursor tab"
}

main() {
    if [ $# -lt 1 ]; then
        usage
    fi
    
    local plan_file="$1"
    local list_only=false
    
    # Check for --list-only flag
    if [ "$2" = "--list-only" ]; then
        list_only=true
    fi
    
    if [ ! -f "$plan_file" ]; then
        echo "Error: File '$plan_file' not found" >&2
        exit 1
    fi

    echo "Parsing: $plan_file"
    echo ""

    # Parse all edges
    local edge_lines
    edge_lines=$(awk '/-->/ {print}' "$plan_file")

    # Maps: phase_id|status|label\n
    local phase_map=""
    local dep_map=""
    local all_ids=""

    # Helper: add phase to phase_map if not already present
    add_phase() {
        local id="$1"; local label="$2"; local status="$3"
        # If already present, skip
        echo "$phase_map" | grep -q "^$id|" && return
        phase_map="$phase_map$id|$status|$label\n"
        all_ids="$all_ids $id"
    }

    # Parse each edge line
    while read -r line; do
        # Split on -->
        left=$(echo "$line" | awk -F'-->' '{print $1}' | xargs)
        right=$(echo "$line" | awk -F'-->' '{print $2}' | xargs)

        # Parse left side
        if echo "$left" | grep -q '\['; then
            # Node definition: PhaseID[Label]:::status
            id=$(echo "$left" | sed -E 's/^([A-Za-z0-9]+)\[.*$/\1/')
            label=$(echo "$left" | sed -E 's/^[A-Za-z0-9]+\[(.*)\]:::.*/\1/')
            status=$(echo "$left" | sed -E 's/.*:::(.*)$/\1/')
            [ -z "$status" ] && status="incomplete"
            add_phase "$id" "$label" "$status"
        else
            # Just an ID
            id=$(echo "$left" | awk '{print $1}')
            add_phase "$id" "$id" "incomplete"
        fi

        # Parse right side
        if echo "$right" | grep -q '\['; then
            id=$(echo "$right" | sed -E 's/^([A-Za-z0-9]+)\[.*$/\1/')
            label=$(echo "$right" | sed -E 's/^[A-Za-z0-9]+\[(.*)\]:::.*/\1/')
            status=$(echo "$right" | sed -E 's/.*:::(.*)$/\1/')
            [ -z "$status" ] && status="incomplete"
            add_phase "$id" "$label" "$status"
        else
            id=$(echo "$right" | awk '{print $1}')
            add_phase "$id" "$id" "incomplete"
        fi

        # Dependency: right depends on left
        left_id=$(echo "$left" | sed -E 's/^([A-Za-z0-9]+).*/\1/')
        right_id=$(echo "$right" | sed -E 's/^([A-Za-z0-9]+).*/\1/')
        dep_map="$dep_map$right_id|$left_id\n"
    done <<EOF
$edge_lines
EOF

    # Print all parsed phases (unique)
    echo "Parsed phases:"
    echo -e "$phase_map" | awk -F'|' '!seen[$1]++ {print $1"|"$2"|"$3}' | while IFS='|' read phase_id status label; do
        [ -z "$phase_id" ] && continue
        echo "  $phase_id: $label ($status)"
    done
    echo ""
    echo "Dependencies:"
    echo -e "$dep_map" | while IFS='|' read to from; do
        [ -z "$to" ] && continue
        echo "  $to depends on $from"
    done
    echo ""

    # Find eligible phases and collect them
    local eligible_phases=""
    local eligible_count=0
    
    echo -e "$phase_map" | awk -F'|' '!seen[$1]++ {print $1"|"$2"|"$3}' | while IFS='|' read phase_id status label; do
        [ -z "$phase_id" ] && continue
        [ "$status" = "complete" ] && continue
        [ "$status" = "inProgress" ] && continue
        [ "$status" = "failed" ] && continue
        
        # Find dependencies for this phase (avoid subshell)
        deps=""
        while IFS='|' read to from; do
            [ -z "$to" ] && continue
            [ "$to" = "$phase_id" ] && deps="$deps $from"
        done <<< "$(echo -e "$dep_map")"
        
        # If no dependencies, eligible
        if [ -z "$deps" ]; then
            echo "$phase_id|$label"
            continue
        fi
        # Check if all dependencies are complete
        all_complete=1
        for dep in $deps; do
            dep_status=$(echo -e "$phase_map" | awk -F'|' -v id="$dep" '!seen[$1]++ && $1==id{print $2}')
            [ "$dep_status" = "complete" ] || all_complete=0
        done
        [ $all_complete -eq 1 ] && echo "$phase_id|$label"
    done > /tmp/eligible_phases_$$

    # Read eligible phases from temp file
    eligible_phases=$(cat /tmp/eligible_phases_$$)
    eligible_count=$(echo "$eligible_phases" | grep -c . || echo "0")
    rm -f /tmp/eligible_phases_$$

    echo "Eligible phases:"
    if [ "$eligible_count" -eq 0 ]; then
        echo "  No eligible phases found."
        exit 0
    fi
    
    # Display eligible phases
    echo "$eligible_phases" | while IFS='|' read phase_id label; do
        [ -z "$phase_id" ] && continue
        echo "  $phase_id: $label"
    done
    echo ""

    # Spawn agents if not in list-only mode
    if [ "$list_only" = false ]; then
        echo "Spawning agents..."
        echo ""
        
        # Get spec name and imp directory from plan file path
        local imp_dir
        imp_dir=$(basename "$(dirname "$plan_file")")
        local spec_name
        spec_name=$(echo "$imp_dir" | sed 's/^imp-//')
        
        # Spawn agent for each eligible phase
        echo "$eligible_phases" | while IFS='|' read phase_id label; do
            [ -z "$phase_id" ] && continue
            spawn_agent "$phase_id" "$label" "$spec_name" "$imp_dir" "$plan_file"
            sleep 1  # Brief pause between spawns
        done
        
        echo ""
        echo "✓ Spawned $eligible_count agents successfully"
    else
        echo "List-only mode: No agents spawned"
    fi
}

main "$@" 