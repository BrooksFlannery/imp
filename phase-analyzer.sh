#!/bin/bash

# Phase Analyzer Script
# Reads a spec file and returns incomplete phases in order

set -e

# Function to display usage
usage() {
    echo "Usage: $0 <spec-file.mdx>"
    echo "Returns space-separated phase names for incomplete phases"
    exit 2
}

# Function to check if file exists
check_file() {
    if [[ ! -f "$1" ]]; then
        echo "Error: File '$1' not found" >&2
        exit 2
    fi
}

# Function to parse phases and check completion
parse_phases() {
    local spec_file="$1"
    local incomplete_phases=()
    local current_phase=""
    local phase_complete=true
    
    # Read file line by line
    while IFS= read -r line; do
        # Check for phase headers: ### Phase X: or ### Phase Xa:
        if [[ $line =~ ^###[[:space:]]+Phase[[:space:]]+([0-9]+[a-z]?):[[:space:]]*(.*)$ ]]; then
            # If we have a previous phase and it's incomplete, add it
            if [[ -n "$current_phase" && "$phase_complete" == "false" ]]; then
                incomplete_phases+=("$current_phase")
            fi
            
            # Start new phase
            phase_number="${BASH_REMATCH[1]}"
            phase_title="${BASH_REMATCH[2]}"
            current_phase="Phase $phase_number: $phase_title"
            phase_complete=true
        fi
        
        # Check for incomplete task lines: - [ ] or - [ ]text
        if [[ $line =~ ^-[[:space:]]+\[[[:space:]]\][[:space:]]* ]]; then
            phase_complete=false
        fi
    done < "$spec_file"
    
    # Check the last phase
    if [[ -n "$current_phase" && "$phase_complete" == "false" ]]; then
        incomplete_phases+=("$current_phase")
    fi
    
    # Return incomplete phases
    if [[ ${#incomplete_phases[@]} -gt 0 ]]; then
        printf '"%s" ' "${incomplete_phases[@]}"
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