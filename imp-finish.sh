#!/usr/bin/env bash

# IMP Finish Script
# - Takes a phase name and path as arguments
# - Updates the phase status from any state to complete in imp-plan.md
# - Creates git branch, commits changes, pushes to remote, and creates PR

set -e

usage() {
  echo "Usage: $0 <phase-name> <imp-plan-path>"
  echo "Example: $0 'Phase 1: Project Setup and Infrastructure' .imp/imp-mock-spec/imp-plan.md"
  echo "Example: $0 'Phase 1: Project Setup and Infrastructure' .imp/imp-mock-spec"
  echo ""
  echo "This script will:"
  echo "  1. Use the provided path to find imp-plan.md"
  echo "  2. Update the specified phase status to complete"
  echo "  3. Create git branch: imp/phase-name"
  echo "  4. Commit all changes with standard message"
  echo "  5. Push branch to origin"
  echo "  6. Create pull request"
  exit 1
}

# Function to validate git setup
validate_git_setup() {
    echo "Validating git setup..."
    # Check if we're in a git repository
    if [ ! -d ".git" ]; then
        echo "Error: Not in a git repository" >&2
        exit 1
    fi
    
    # Check if git remote origin is configured
    if ! git remote get-url origin >/dev/null 2>&1; then
        echo "Error: Git remote 'origin' not configured" >&2
        exit 1
    fi
    
    # Check if git user is configured
    if [ -z "$(git config user.name)" ] || [ -z "$(git config user.email)" ]; then
        echo "Error: Git user not configured. Please set user.name and user.email" >&2
        exit 1
    fi
    
    echo "✓ Git setup validated"
}

# Function to create phase branch
create_phase_branch() {
    local phase_name="$1"
    local branch_name="imp/$(echo "$phase_name" | tr ' -' '_' | tr ':' '-')"
    
    echo "Creating git branch: $branch_name"
    # Check if branch already exists
    if git show-ref --verify --quiet refs/heads/"$branch_name"; then
        echo "Error: Branch '$branch_name' already exists" >&2
        exit 1
    fi
    
    # Create and checkout new branch
    if ! git checkout -b "$branch_name"; then
        echo "Error: Failed to create branch $branch_name" >&2
        exit 1
    fi
    
    echo "✓ Created and checked out branch: $branch_name"
    echo "$branch_name" #Return branch name for later use
}

# Function to commit phase changes
commit_phase_changes() {
    local phase_name="$1"
    local commit_message="Complete $phase_name"
    
    echo "Committing changes..."
    # Check if there are any changes to commit
    if git diff-index --quiet HEAD --; then
        echo "Warning: No changes to commit"
        return 0
    fi
    
    # Stage all changes
    if ! git add .; then
        echo "Error: Failed to stage changes" >&2
        exit 1
    fi
    
    # Create commit
    if ! git commit -m "$commit_message"; then
        echo "Error: Failed to create commit" >&2
        exit 1
    fi
    
    echo "✓ Committed changes: $commit_message"
}

# Function to push branch and create PR
push_phase_branch() {
    local branch_name="$1"
    local phase_name="$2"
    echo "Pushing branch to origin..."
    
    # Push branch to origin
    if ! git push -u origin "$branch_name"; then
        echo "Error: Failed to push branch $branch_name to origin" >&2
        exit 1
    fi
    
    echo "✓ Pushed branch to origin"
    
    # Create pull request using GitHub CLI if available
    if command -v gh >/dev/null 2>&1; then
        echo "Creating pull request..."
        local pr_title="Complete $phase_name"
        local pr_body="This PR completes the implementation of: $phase_name"
        
        if ! gh pr create --title "$pr_title" --body "$pr_body" --base main; then
            echo "Warning: Failed to create pull request automatically" >&2
            echo "Please create PR manually at: $(git remote get-url origin | sed 's/\.git$//')/compare/main...$branch_name"
        else
            echo "✓ Pull request created"
        fi
    else
        echo "GitHub CLI not found. Please create PR manually at: $(git remote get-url origin | sed 's/\.git$//')/compare/main...$branch_name"
    fi
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
    
    echo "IMP Finish: $phase_name"
    echo "Path: $imp_path"
    echo ""
    
    # Validate git setup first
    validate_git_setup
    
    # Resolve the imp-plan.md path
    echo "Resolving imp-plan.md path..."
    local plan_file
    plan_file=$(resolve_plan_path "$imp_path")
    echo "Using plan file: $plan_file"
    
    # Update the phase status in Mermaid diagram
    echo "Updating phase status in: $plan_file"
    update_phase_status "$plan_file" "$phase_name"
    
    # Create git branch
    local branch_name
    branch_name=$(create_phase_branch "$phase_name")
    
    # Commit changes
    commit_phase_changes "$phase_name"
    
    # Push branch and create PR
    push_phase_branch "$branch_name" "$phase_name"
    
    echo ""
    echo "✓ Phase completion recorded successfully"
    echo "✓ Git operations completed"
    
    # Call imp-spawner.sh to spawn agents for newly eligible phases
    echo ""
    echo "Checking for newly eligible phases..."
    # Get IMP directory (where this script is located)
    IMP_DIR=$(dirname "$(realpath "$0")")
    "$IMP_DIR/imp-spawner.sh" "$plan_file"
}

main "$@" 