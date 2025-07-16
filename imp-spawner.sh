#!/usr/bin/env bash

# IMP Spawner Script (Bash 3.2 compatible)
# - Parses imp-plan.md Mermaid diagram (edges define nodes)
# - Prints eligible phases (no dependencies or all dependencies complete)

set -e

usage() {
  echo "Usage: $0 <imp-plan.md-file>"
  echo "Example: $0 .imp/imp-mock-spec/imp-plan.md"
  exit 1
}

main() {
  if [ $# -ne 1 ]; then
    usage
  fi
  local plan_file="$1"
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

  # For each phase, check if all dependencies are complete
  echo "Eligible phases:"
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
      echo "  $phase_id: $label"
      continue
    fi
    # Check if all dependencies are complete
    all_complete=1
    for dep in $deps; do
      dep_status=$(echo -e "$phase_map" | awk -F'|' -v id="$dep" '!seen[$1]++ && $1==id{print $2}')
      [ "$dep_status" = "complete" ] || all_complete=0
    done
    [ $all_complete -eq 1 ] && echo "  $phase_id: $label"
  done
}

main "$@" 