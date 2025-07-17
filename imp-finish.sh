#!/usr/bin/env bash

# IMP Finish Script - HEAVILY DEBUGGED VERSION
# - Takes a phase name and path as arguments
# - Updates the phase status from any state to complete in imp-plan.md
# - Creates git branch, commits changes, pushes to remote, and creates PR
# - Spawns agents for newly eligible phases

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Debug flag - set to 1 to enable verbose debugging
DEBUG=${IMP_DEBUG:-0}

# Logging functions with debug support
log() {
    echo -e "${BLUE}[IMP]${NC} $1"
}

debug() {
    if [ "$DEBUG" = "1" ]; then
        echo -e "${PURPLE}[IMP DEBUG]${NC} $1"
    fi
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

info() {
    echo -e "${CYAN}[IMP INFO]${NC} $1"
}

usage() {
  echo "Usage: $0 <phase-name> <imp-plan-path>"
  echo "Example: $0 'Phase 1: Project Setup and Infrastructure' .imp/imp-mock-spec/imp-plan.md"
  echo "Example: $0 'Phase 1: Project Setup and Infrastructure' .imp/imp-mock-spec"
  echo ""
  echo "This script will:"
  echo "  1. Use the provided path to find imp-plan.md"
  echo "  2. Update the specified phase status to complete"
  echo "  3. If git is available:"
  echo "     - Create git branch: imp/phase-name"
  echo "     - Commit all changes with standard message"
  echo "     - Push branch to origin"
  echo "     - Create pull request"
  echo "  4. If git is not available:"
  echo "     - Skip all git operations"
  echo "     - Continue with phase completion"
  echo "  5. Spawn agents for newly eligible phases"
  exit 1
}

# Function to validate git setup with extensive debugging
validate_git_setup() {
    debug "validate_git_setup() called"
    debug "IMP_GIT_AVAILABLE = '$IMP_GIT_AVAILABLE'"
    
    # Check if git operations are enabled
    if [ "$IMP_GIT_AVAILABLE" != "1" ]; then
        info "Git operations disabled - skipping git validation"
        return 1
    fi
    
    echo "Validating git setup..."
    debug "Checking if we're in a git repository..."
    
    # Check if we're in a git repository
    if [ ! -d ".git" ]; then
        error "Not in a git repository"
        debug "Current directory: $(pwd)"
        debug "Directory contents: $(ls -la)"
        exit 1
    fi
    
    debug "✓ In git repository"
    
    # Check if git remote origin is configured
    debug "Checking git remote origin..."
    if ! git remote get-url origin >/dev/null 2>&1; then
        error "Git remote 'origin' not configured"
        debug "Available remotes: $(git remote -v)"
        exit 1
    fi
    
    debug "✓ Git remote origin configured: $(git remote get-url origin)"
    
    # Check if git user is configured
    debug "Checking git user configuration..."
    local git_user_name=$(git config user.name)
    local git_user_email=$(git config user.email)
    
    if [ -z "$git_user_name" ] || [ -z "$git_user_email" ]; then
        error "Git user not configured. Please set user.name and user.email"
        debug "user.name = '$git_user_name'"
        debug "user.email = '$git_user_email'"
        exit 1
    fi
    
    debug "✓ Git user configured: $git_user_name <$git_user_email>"
    
    echo "✓ Git setup validated"
    return 0
}

# Function to create phase branch with extensive debugging
create_phase_branch() {
    debug "create_phase_branch() called with phase_name='$1'"
    
    # Check if git operations are enabled
    if [ "$IMP_GIT_AVAILABLE" != "1" ]; then
        info "Git operations disabled - skipping branch creation"
        return 0
    fi
    
    local phase_name="$1"
    local branch_name="imp/$(echo "$phase_name" | tr ' -' '_' | tr ':' '-')"
    
    debug "Original phase name: '$phase_name'"
    debug "Generated branch name: '$branch_name'"
    
    echo "Creating git branch: $branch_name" >&2
    
    # Check if branch already exists
    debug "Checking if branch '$branch_name' already exists..."
    if git show-ref --verify --quiet refs/heads/"$branch_name"; then
        error "Branch '$branch_name' already exists"
        debug "Existing branches: $(git branch -a)"
        exit 1
    fi
    
    debug "✓ Branch '$branch_name' does not exist"
    
    # Get current branch before creating new one
    local current_branch=$(git branch --show-current)
    debug "Current branch before checkout: '$current_branch'"
    
    # Create and checkout new branch
    debug "Creating and checking out branch '$branch_name'..."
    if ! git checkout -b "$branch_name"; then
        error "Failed to create branch $branch_name"
        debug "Git status: $(git status --porcelain)"
        exit 1
    fi
    
    debug "✓ Successfully created and checked out branch '$branch_name'"
    
    # Verify we're on the correct branch
    local new_branch=$(git branch --show-current)
    debug "Current branch after checkout: '$new_branch'"
    
    if [ "$new_branch" != "$branch_name" ]; then
        error "Branch checkout failed - expected '$branch_name', got '$new_branch'"
        exit 1
    fi
    
    echo "✓ Created and checked out branch: $branch_name" >&2
    
    # Return ONLY the branch name, no extra output
    printf "%s" "$branch_name"
}

# Function to commit phase changes with extensive debugging
commit_phase_changes() {
    debug "commit_phase_changes() called with phase_name='$1'"
    
    # Check if git operations are enabled
    if [ "$IMP_GIT_AVAILABLE" != "1" ]; then
        info "Git operations disabled - skipping commit"
        return 0
    fi
    
    local phase_name="$1"
    local commit_message="Complete $phase_name"
    
    debug "Commit message: '$commit_message'"
    
    echo "Committing changes..."
    
    # Check current git status
    debug "Current git status:"
    debug "$(git status --porcelain)"
    
    # Check if there are any changes to commit
    debug "Checking if there are changes to commit..."
    if git diff-index --quiet HEAD --; then
        warning "No changes to commit"
        debug "Working directory is clean"
        return 0
    fi
    
    debug "✓ Changes detected, proceeding with commit"
    
    # Stage all changes
    debug "Staging all changes..."
    if ! git add .; then
        error "Failed to stage changes"
        debug "Git add output: $?"
        exit 1
    fi
    
    debug "✓ Changes staged successfully"
    
    # Show what's staged
    debug "Staged changes:"
    debug "$(git diff --cached --name-only)"
    
    # Create commit
    debug "Creating commit with message: '$commit_message'"
    if ! git commit -m "$commit_message"; then
        error "Failed to create commit"
        debug "Git commit output: $?"
        exit 1
    fi
    
    debug "✓ Commit created successfully"
    
    # Show commit details
    local commit_hash=$(git rev-parse HEAD)
    debug "Commit hash: $commit_hash"
    debug "Commit details: $(git log -1 --oneline)"
    
    echo "✓ Committed changes: $commit_message"
}

# Function to push branch with extensive debugging
push_phase_branch() {
    debug "push_phase_branch() called with branch_name='$1', phase_name='$2'"
    
    # Check if git operations are enabled
    if [ "$IMP_GIT_AVAILABLE" != "1" ]; then
        info "Git operations disabled - skipping push and PR creation"
        return 0
    fi
    
    local branch_name="$1"
    local phase_name="$2"
    
    debug "Branch name to push: '$branch_name'"
    debug "Phase name: '$phase_name'"
    
    echo "Pushing branch to origin..."
    
    # Verify we're on the correct branch
    local current_branch=$(git branch --show-current)
    debug "Current branch: '$current_branch'"
    debug "Target branch: '$branch_name'"
    
    if [ "$current_branch" != "$branch_name" ]; then
        error "Not on correct branch - expected '$branch_name', got '$current_branch'"
        exit 1
    fi
    
    # Check remote configuration
    debug "Remote configuration:"
    debug "$(git remote -v)"
    
    # Push branch to origin
    debug "Pushing branch '$branch_name' to origin..."
    if ! git push -u origin "$branch_name"; then
        error "Failed to push branch $branch_name to origin"
        debug "Git push output: $?"
        debug "Git status: $(git status)"
        exit 1
    fi
    
    debug "✓ Branch pushed successfully"
    echo "✓ Pushed branch to origin"
    info "Branch pushed successfully. You can create a pull request manually if needed."
}

# Function to resolve imp-plan.md path with debugging
resolve_plan_path() {
    debug "resolve_plan_path() called with path='$1'"
    
    local path="$1"
    local plan_file
    
    debug "Input path: '$path'"
    debug "Path type check:"
    debug "  -d check: $([ -d "$path" ] && echo "directory" || echo "not directory")"
    debug "  -f check: $([ -f "$path" ] && echo "file" || echo "not file")"
    
    # If path is a directory, look for imp-plan.md inside it
    if [ -d "$path" ]; then
        plan_file="$path/imp-plan.md"
        debug "Path is directory, looking for imp-plan.md at: '$plan_file'"
    # If path is already a file, use it directly
    elif [ -f "$path" ]; then
        plan_file="$path"
        debug "Path is file, using directly: '$plan_file'"
    else
        error "Path '$path' is not a valid directory or file"
        debug "Current directory: $(pwd)"
        debug "Directory contents: $(ls -la)"
        exit 1
    fi
    
    # Verify the plan file exists
    debug "Checking if plan file exists: '$plan_file'"
    if [ ! -f "$plan_file" ]; then
        error "imp-plan.md not found at '$plan_file'"
        debug "Directory contents of $(dirname "$plan_file"): $(ls -la "$(dirname "$plan_file")" 2>/dev/null || echo "Directory not accessible")"
        exit 1
    fi
    
    debug "✓ Plan file found: '$plan_file'"
    echo "$plan_file"
}

# Function to update phase status in Mermaid diagram with debugging
update_phase_status() {
    debug "update_phase_status() called with plan_file='$1', phase_name='$2'"
    
    local plan_file="$1"
    local phase_name="$2"
    local temp_file
    
    debug "Plan file: '$plan_file'"
    debug "Phase name: '$phase_name'"
    
    temp_file=$(mktemp)
    debug "Temporary file: '$temp_file'"
    
    # Check if phase exists and get current status
    local phase_line
    local current_status
    
    debug "Searching for phase in plan file..."
    phase_line=$(grep -n "\[$phase_name\]" "$plan_file" || true)
    debug "Phase line found: '$phase_line'"
    
    if [ -z "$phase_line" ]; then
        error "Phase '$phase_name' not found in $plan_file"
        debug "Available phases in file:"
        debug "$(grep -E '\[.*\]:::' "$plan_file" || echo "No phases found")"
        exit 1
    fi
    
    # Extract current status
    current_status=$(echo "$phase_line" | sed -E 's/.*:::(.*)$/\1/')
    debug "Current status: '$current_status'"
    
    if [ "$current_status" = "complete" ]; then
        error "Phase '$phase_name' is already marked as complete"
        exit 1
    fi
    
    if [ "$current_status" != "inProgress" ]; then
        warning "Phase '$phase_name' is in state '$current_status', not 'inProgress'. Forcing to 'complete'."
    fi
    
    # Update the status to complete (from any state except already complete)
    debug "Updating phase status to complete..."
    sed -E "s/\[$phase_name\]:::(incomplete|inProgress|failed)/\[$phase_name\]:::complete/g" "$plan_file" > "$temp_file"
    
    # Verify the change was made
    debug "Verifying status update..."
    if ! grep -q "\[$phase_name\]:::complete" "$temp_file"; then
        error "Failed to update phase status in $plan_file"
        debug "Temp file contents around phase:"
        debug "$(grep -A5 -B5 "\[$phase_name\]" "$temp_file" || echo "Phase not found in temp file")"
        rm -f "$temp_file"
        exit 1
    fi
    
    debug "✓ Status update verified"
    
    # Replace original file
    debug "Replacing original file with updated content..."
    mv "$temp_file" "$plan_file"
    
    echo "✓ Updated phase '$phase_name' status to complete"
}

# Function to spawn agents with debugging
spawn_agents() {
    debug "spawn_agents() called with plan_file='$1'"
    
    local plan_file="$1"
    
    echo ""
    log "Checking for newly eligible phases..."
    
    # Get IMP directory (where this script is located)
    local IMP_DIR=$(dirname "$(realpath "$0")")
    local spawner_script="$IMP_DIR/imp-spawner.sh"
    
    debug "IMP_DIR: '$IMP_DIR'"
    debug "Spawner script: '$spawner_script'"
    debug "Plan file: '$plan_file'"
    
    # Check if spawner script exists
    if [ ! -f "$spawner_script" ]; then
        error "Spawner script not found: $spawner_script"
        debug "IMP_DIR contents: $(ls -la "$IMP_DIR")"
        return 1
    fi
    
    debug "✓ Spawner script found"
    
    # Check if plan file exists
    if [ ! -f "$plan_file" ]; then
        error "Plan file not found: $plan_file"
        return 1
    fi
    
    debug "✓ Plan file found"
    
    # Make spawner script executable
    debug "Making spawner script executable..."
    chmod +x "$spawner_script"
    
    # Call spawner script
    debug "Calling spawner script: '$spawner_script' '$plan_file'"
    if ! "$spawner_script" "$plan_file"; then
        warning "Spawner script failed with exit code $?"
        debug "This is not fatal - continuing..."
        return 1
    fi
    
    debug "✓ Spawner script completed successfully"
    return 0
}

main() {
    debug "main() called with $# arguments: $*"
    
    if [ $# -ne 2 ]; then
        usage
    fi
    
    local phase_name="$1"
    local imp_path="$2"
    
    # Validate git setup first (this will return early if git is disabled)
    debug "Calling validate_git_setup..."
    validate_git_setup || true  # Don't exit on failure - git being disabled is expected
    local git_available=$?
    debug "Git setup validation result: $git_available"
    
    # Resolve the imp-plan.md path
    echo "Resolving imp-plan.md path..."
    local plan_file
    plan_file=$(resolve_plan_path "$imp_path")
    echo "Using plan file: $plan_file"
    
    # Update the phase status in Mermaid diagram
    echo "Updating phase status in: $plan_file"
    update_phase_status "$plan_file" "$phase_name"
    
    # Create git branch (conditional)
    local branch_name=""
    if [ "$IMP_GIT_AVAILABLE" = "1" ]; then
        debug "Creating git branch..."
        branch_name=$(create_phase_branch "$phase_name")
        debug "Branch name returned: '$branch_name'"
    else
        debug "Skipping git branch creation (git not available)"
    fi
    
    # Commit changes (conditional)
    debug "Committing changes..."
    commit_phase_changes "$phase_name"
    
    # Push branch (conditional, no PR creation)
    if [ "$IMP_GIT_AVAILABLE" = "1" ] && [ -n "$branch_name" ]; then
        debug "Pushing branch..."
        push_phase_branch "$branch_name" "$phase_name"
    else
        debug "Skipping branch push (git not available or no branch name)"
    fi
    
    echo ""
    success "Phase completion recorded successfully"
    if [ "$IMP_GIT_AVAILABLE" = "1" ]; then
        success "Git operations completed"
    else
        info "Git operations skipped (git not available)"
    fi
    
    # Spawn agents for newly eligible phases
    debug "Spawning agents..."
    spawn_agents "$plan_file"
    
    echo ""
    success "IMP finish completed successfully"
    debug "Script completed with exit code 0"
}

# Set up error handling
trap 'error "Script failed at line $LINENO with exit code $?"' ERR

# Call main function
main "$@" 