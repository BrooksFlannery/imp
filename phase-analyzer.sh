#!/bin/bash

# Phase Analyzer Script
# Reads a spec file and returns incomplete phases in order

set -e

# Function to display usage
usage() {
    echo "Usage: $0 <spec-file.mdx>"
    echo "Returns space-separated phase names for incomplete phases"
    echo ""
    echo "Exit codes:"
    echo "  0: Found phases to spawn"
    echo "  1: All phases complete"
    echo "  2: File not found"
    echo "  3: Duplicate phases found"
    echo "  4: Malformed syntax found"
    exit 2
}

# Function to check if file exists
check_file() {
    if [[ ! -f "$1" ]]; then
        echo "Error: File '$1' not found" >&2
        exit 2
    fi
}

# Function to extract phase number from phase name (e.g., "2a" -> "2", "3" -> "3")
get_phase_number() {
    local phase_id="$1"
    echo "$phase_id" | sed 's/[a-z]//g'
}

# Function to check if phase is parallel (has letter suffix)
is_parallel_phase() {
    local phase_id="$1"
    [[ $phase_id =~ [a-z]$ ]]
}

# Function to parse phases and check completion with smart dependencies
parse_phases() {
    local spec_file="$1"
    
    # Arrays to store phase information (using regular arrays for bash 3.2 compatibility)
    local phase_ids=()
    local phase_complete=()
    local phase_titles=()
    local current_phase_id=""
    local current_phase_title=""
    local current_phase_complete=true
    local duplicate_phases=()
    local malformed_lines=()
    
    # First pass: collect all phases and their completion status
    while IFS= read -r line; do
        # Check for phase headers: ### Phase X: or ### Phase Xa:
        if [[ $line =~ ^###[[:space:]]+Phase[[:space:]]+([0-9]+[a-z]?):[[:space:]]*(.*)$ ]]; then
            # Save previous phase if exists
            if [[ -n "$current_phase_id" ]]; then
                phase_ids+=("$current_phase_id")
                phase_complete+=("$current_phase_complete")
                phase_titles+=("$current_phase_title")
            fi
            
            # Start new phase
            current_phase_id="${BASH_REMATCH[1]}"
            current_phase_title="${BASH_REMATCH[2]}"
            current_phase_complete=true
            
            # Check for duplicates
            for existing_id in "${phase_ids[@]}"; do
                if [[ "$existing_id" == "$current_phase_id" ]]; then
                    duplicate_phases+=("$current_phase_id")
                fi
            done
        elif [[ $line =~ ^###[[:space:]]*Phase ]]; then
            # Looks like a phase header but doesn't match our regex
            fuzzy=$(printf "%s" "$line" | python3 -c "import sys, difflib; l=sys.stdin.read().strip(); patt='### Phase X:'; sim=difflib.SequenceMatcher(None, l, patt).ratio(); print(f'  (fuzzy: {sim:.2f} similarity to phase header)' if sim > 0.5 else '', end='')")
            malformed_lines+=("Malformed phase header: $line$fuzzy")
        elif [[ $line =~ ^-[[:space:]]*\[ ]]; then
            # Looks like a task - check if it matches proper format
            if [[ $line =~ ^-[[:space:]]+\[[[:space:]]\][[:space:]]* ]] || [[ $line =~ ^-[[:space:]]+\[x\][[:space:]]* ]]; then
                # This is a properly formatted task
                if [[ $line =~ ^-[[:space:]]+\[[[:space:]]\][[:space:]]* ]]; then
                    current_phase_complete=false
                fi
            else
                # This is a malformed task
                fuzzy=$(printf "%s" "$line" | python3 -c "import sys, difflib; l=sys.stdin.read().strip(); patt='- [ ] Task'; patt2='- [x] Task'; sim1=difflib.SequenceMatcher(None, l, patt).ratio(); sim2=difflib.SequenceMatcher(None, l, patt2).ratio(); best=max(sim1, sim2); print(f'  (fuzzy: {best:.2f} similarity to task line)' if best > 0.5 else '', end='')")
                malformed_lines+=("Malformed task: $line$fuzzy")
            fi
        fi
        
    done < "$spec_file"
    
    # Save the last phase
    if [[ -n "$current_phase_id" ]]; then
        phase_ids+=("$current_phase_id")
        phase_complete+=("$current_phase_complete")
        phase_titles+=("$current_phase_title")
    fi
    
    # Check for duplicates and exit with error
    if [[ ${#duplicate_phases[@]} -gt 0 ]]; then
        echo "Error: Duplicate phase numbers found: ${duplicate_phases[*]}" >&2
        echo "Please fix the spec file to remove duplicates." >&2
        exit 3
    fi
    
    # Check for malformed lines and exit with error
    if [[ ${#malformed_lines[@]} -gt 0 ]]; then
        echo "Error: Malformed syntax found:" >&2
        for line in "${malformed_lines[@]}"; do
            echo "  $line" >&2
        done
        echo "Please fix the spec file formatting." >&2
        exit 4
    fi

    # Find the lowest incomplete phase number
    local lowest_incomplete_num=""
    for i in $(seq 0 $((${#phase_ids[@]} - 1))); do
        local phase_id="${phase_ids[$i]}"
        local phase_num=$(get_phase_number "$phase_id")
        local is_complete="${phase_complete[$i]}"
        if [[ "$is_complete" == "false" ]]; then
            if [[ -z "$lowest_incomplete_num" || $phase_num -lt $lowest_incomplete_num ]]; then
                lowest_incomplete_num=$phase_num
            fi
        fi
    done

    for i in $(seq 0 $((${#phase_ids[@]} - 1))); do
        local phase_id="${phase_ids[$i]}"
        local phase_num=$(get_phase_number "$phase_id")
        local is_complete="${phase_complete[$i]}"
        
        # Only allow phases with the lowest incomplete number
        if [[ "$is_complete" == "false" && $phase_num -eq $lowest_incomplete_num ]]; then
            local phase_name="Phase $phase_id: ${phase_titles[$i]}"
            available_phases+=("$phase_name")
        fi
    done
    
    # Return available phases
    if [[ ${#available_phases[@]} -gt 0 ]]; then
        printf '"%s" ' "${available_phases[@]}"
        echo
        exit 0
    else
        echo "All phases complete"
        exit 1
    fi
}

# Main execution
main() {
    # Check arguments
    if [[ $# -ne 1 ]]; then
        usage
    fi
    
    local spec_file="$1"
    
    # Check if file exists
    check_file "$spec_file"
    
    # Parse phases
    parse_phases "$spec_file"
}

# Run main function
main "$@" 