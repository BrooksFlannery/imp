#!/bin/bash

# IMP (Implementation Management Platform) - Main Entry Point
# Orchestrates the entire implementation workflow from spec to completion

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
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

info() {
    echo -e "${CYAN}[IMP INFO]${NC} $1"
}

# Version
IMP_VERSION="0.2.0"

# Get IMP installation directory (where this script is located)
get_imp_dir() {
    # Get the directory where this script is located
    local script_dir=""
    if [[ -L "$0" ]]; then
        # If this script is a symlink, follow it
        script_dir=$(dirname "$(readlink -f "$0")")
    else
        # Otherwise, get the directory of this script
        script_dir=$(dirname "$(realpath "$0")")
    fi
    echo "$script_dir"
}

# Set IMP directory
IMP_DIR=$(get_imp_dir)

# Help function
show_help() {
    echo "IMP (Implementation Management Platform) v$IMP_VERSION"
    echo ""
    echo "Usage: $0 <spec-file> | <command> [options]"
    echo ""
    echo "Spec-compliant flow (recommended):"
    echo "  $0 <spec-file>              Initialize or continue implementation"
    echo ""
    echo "Fine-grained commands:"
    echo "  init <spec-file>           Initialize a new implementation from spec"
    echo "  plan <spec-dir>            Generate implementation plan from spec"
    echo "  spawn <plan-file>          Spawn agents for eligible phases"
    echo "  finish <phase> <plan-path> Mark a phase as complete"
    echo "  status <plan-file>         Show current implementation status"
    echo "  list <plan-file>           List eligible phases (no spawn)"
    echo "  check                      Validate IMP environment and dependencies"
    echo "  version                    Show IMP version"
    echo "  uninstall                  Remove IMP from your system"
    echo ""
    echo "Examples:"
    echo "  $0 my-feature-spec.md      # Spec-compliant: init or continue"
    echo "  $0 init my-feature-spec.md # Explicit initialization"
    echo "  $0 plan .imp/imp-my-feature"
    echo "  $0 spawn .imp/imp-my-feature/imp-plan.md"
    echo "  $0 finish 'Phase 1: Setup' .imp/imp-my-feature"
    echo "  $0 status .imp/imp-my-feature/imp-plan.md"
    echo "  $0 list .imp/imp-my-feature/imp-plan.md"
    echo "  $0 uninstall                # Remove IMP from your system"
    echo ""
    echo "For detailed help on any command:"
    echo "  $0 <command> --help"
}

# Check if we're in a git repository
check_git_repo() {
    if [ ! -d ".git" ]; then
        error "Not in a git repository. IMP requires a git repository to track implementation progress."
        exit 1
    fi
    success "Git repository detected"
}

# Check for required dependencies
check_dependencies() {
    local missing_deps=()
    
    # Check for required commands
    for cmd in jq awk sed grep; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    # Check for macOS-specific commands
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! command -v "osascript" >/dev/null 2>&1; then
            missing_deps+=("osascript")
        fi
        if ! command -v "pbcopy" >/dev/null 2>&1; then
            missing_deps+=("pbcopy")
        fi
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        error "Missing required dependencies: ${missing_deps[*]}"
        exit 1
    fi
    
    success "All required dependencies available"
}

# Check for required IMP files
check_imp_files() {
    local missing_files=()
    
    for file in imp-init.sh imp-plan.sh imp-spawner.sh imp-finish.sh imp-agent.prompt imp-plan-prompt.txt; do
        if [ ! -f "$IMP_DIR/$file" ]; then
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -ne 0 ]; then
        error "Missing required IMP files: ${missing_files[*]}"
        error "Please ensure all IMP files are present in: $IMP_DIR"
        exit 1
    fi
    
    success "All required IMP files present"
}

# Check if Cursor is available
check_cursor() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! osascript -e 'tell application "Cursor" to version' >/dev/null 2>&1; then
            warning "Cursor application not found or not accessible"
            warning "Agent spawning functionality will be limited"
            return 1
        fi
        success "Cursor application detected"
    else
        warning "Cursor integration only available on macOS"
        warning "Agent spawning functionality will be limited"
        return 1
    fi
}

# Environment validation
validate_environment() {
    log "Validating IMP environment..."
    
    check_dependencies
    check_imp_files
    check_cursor
    
    success "Environment validation complete"
}

# Function to check git setup and prompt user if needed
check_git_setup() {
    # Check if we're in a git repository
    if [ ! -d ".git" ]; then
        warning "Git repository not found in current directory"
        echo ""
        read -p "Git not found. Do you want to stop and set up git/github? (y/N): " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            info "Please set up git and github for your project, then rerun: imp $1"
            info "To set up git:"
            info "  1. git init"
            info "  2. git add ."
            info "  3. git commit -m 'Initial commit'"
            info "  4. Create repository on GitHub"
            info "  5. git remote add origin <your-repo-url>"
            info "  6. git push -u origin main"
            exit 0
        else
            info "Continuing without git integration"
            return 1  # Indicate git not available
        fi
    else
        success "Git repository detected"
        return 0  # Indicate git is available
    fi
}

# New handler for spec-compliant flow
handle_spec_file() {
    local spec_file="$1"
    
    # Validate spec file exists and is readable
    if [ ! -f "$spec_file" ]; then
        error "Specification file not found: $spec_file"
        exit 1
    fi

    if [ ! -r "$spec_file" ]; then
        error "Specification file is not readable: $spec_file"
        exit 1
    fi

    # Check git setup and get result
    local git_available
    if check_git_setup "$spec_file"; then
        git_available=1  # Git is available
    else
        git_available=0  # Git is not available
    fi
    
    # Store git availability for later use (we'll pass this to other scripts)
    export IMP_GIT_AVAILABLE=$git_available
    
    # Get absolute path of spec file
    local spec_file_abs=$(realpath "$spec_file")
    
    # Extract spec name from filename (remove extension and path)
    local spec_name=$(basename "$spec_file" | sed 's/\.[^.]*$//')
    
    # Check if IMP repository already exists for this spec
    local imp_dir=".imp/imp-$spec_name"
    local plan_file="$imp_dir/imp-plan.md"
    
    if [ -d "$imp_dir" ] && [ -f "$plan_file" ]; then
        log "IMP repository exists for spec: $spec_name"
        log "Continuing with existing implementation..."
        "$IMP_DIR/imp-spawner.sh" "$plan_file"
    else
        log "IMP repository does not exist for spec: $spec_name"
        log "Initializing new implementation..."
        "$IMP_DIR/imp-init.sh" "$spec_file"
    fi
}

# Command handlers
handle_init() {
    if [ $# -eq 0 ]; then
        error "No specification file provided"
        echo "Usage: $0 init <spec-file>"
        exit 1
    fi
    
    if [ "$1" = "--help" ]; then
        echo "Usage: $0 init <spec-file>"
        echo ""
        echo "Initialize a new implementation from a specification file."
        echo ""
        echo "Arguments:"
        echo "  spec-file    Path to the specification file to process"
        echo ""
        echo "This command will:"
        echo "  1. Validate the specification file"
        echo "  2. Create .imp directory structure"
        echo "  3. Initialize configuration"
        echo "  4. Spawn plan generation agent"
        exit 0
    fi
    
    log "Initializing new implementation from: $1"
    "$IMP_DIR/imp-init.sh" "$1"
}

handle_plan() {
    if [ $# -eq 0 ]; then
        error "No spec directory provided"
        echo "Usage: $0 plan <spec-dir>"
        exit 1
    fi
    
    if [ "$1" = "--help" ]; then
        echo "Usage: $0 plan <spec-dir>"
        echo ""
        echo "Generate implementation plan from specification."
        echo ""
        echo "Arguments:"
        echo "  spec-dir     Path to the IMP spec directory (e.g., .imp/imp-specname)"
        echo ""
        echo "This command will:"
        echo "  1. Validate the spec directory"
        echo "  2. Spawn plan generation agent"
        echo "  3. Generate analysis.json and imp-plan.md"
        exit 0
    fi
    
    log "Generating implementation plan for: $1"
    "$IMP_DIR/imp-plan.sh" "$1"
}

handle_spawn() {
    if [ $# -eq 0 ]; then
        error "No plan file provided"
        echo "Usage: $0 spawn <plan-file>"
        exit 1
    fi
    
    if [ "$1" = "--help" ]; then
        echo "Usage: $0 spawn <plan-file>"
        echo ""
        echo "Spawn agents for eligible phases."
        echo ""
        echo "Arguments:"
        echo "  plan-file    Path to the imp-plan.md file"
        echo ""
        echo "This command will:"
        echo "  1. Parse the Mermaid diagram"
        echo "  2. Identify eligible phases"
        echo "  3. Spawn Cursor agents for each eligible phase"
        exit 0
    fi
    
    log "Spawning agents for eligible phases in: $1"
    "$IMP_DIR/imp-spawner.sh" "$1"
}

handle_finish() {
    if [ $# -lt 2 ]; then
        error "Insufficient arguments"
        echo "Usage: $0 finish <phase> <plan-path>"
        exit 1
    fi
    
    if [ "$1" = "--help" ]; then
        echo "Usage: $0 finish <phase> <plan-path>"
        echo ""
        echo "Mark a phase as complete."
        echo ""
        echo "Arguments:"
        echo "  phase        Name of the phase to mark complete"
        echo "  plan-path    Path to imp-plan.md or spec directory"
        echo ""
        echo "This command will:"
        echo "  1. Update the phase status to complete"
        echo "  2. Check for newly eligible phases"
        echo "  3. Spawn agents for new eligible phases"
        exit 0
    fi
    
    # Check git setup and get result (same as in handle_spec_file)
    local git_available
    if check_git_setup "finish"; then
        git_available=1  # Git is available
    else
        git_available=0  # Git is not available
    fi
    
    # Store git availability for later use
    export IMP_GIT_AVAILABLE=$git_available
    
    log "Marking phase as complete: $1"
    "$IMP_DIR/imp-finish.sh" "$1" "$2"
}

handle_status() {
    if [ $# -eq 0 ]; then
        error "No plan file provided"
        echo "Usage: $0 status <plan-file>"
        exit 1
    fi
    
    if [ "$1" = "--help" ]; then
        echo "Usage: $0 status <plan-file>"
        echo ""
        echo "Show current implementation status."
        echo ""
        echo "Arguments:"
        echo "  plan-file    Path to the imp-plan.md file"
        echo ""
        echo "This command will:"
        echo "  1. Parse the Mermaid diagram"
        echo "  2. Display phase statuses and progress"
        exit 0
    fi
    
    log "Showing status for: $1"
    "$IMP_DIR/imp-spawner.sh" "$1" --list-only
}

handle_list() {
    if [ $# -eq 0 ]; then
        error "No plan file provided"
        echo "Usage: $0 list <plan-file>"
        exit 1
    fi
    
    if [ "$1" = "--help" ]; then
        echo "Usage: $0 list <plan-file>"
        echo ""
        echo "List eligible phases without spawning agents."
        echo ""
        echo "Arguments:"
        echo "  plan-file    Path to the imp-plan.md file"
        echo ""
        echo "This command will:"
        echo "  1. Parse the Mermaid diagram"
        echo "  2. List all eligible phases"
        echo "  3. Not spawn any agents"
        exit 0
    fi
    
    log "Listing eligible phases for: $1"
    "$IMP_DIR/imp-spawner.sh" "$1" --list-only
}

handle_check() {
    if [ "$1" = "--help" ]; then
        echo "Usage: $0 check"
        echo ""
        echo "Validate IMP environment and dependencies."
        echo ""
        echo "This command will:"
        echo "  1. Check git repository"
        echo "  2. Validate dependencies"
        echo "  3. Check required files"
        echo "  4. Verify Cursor integration"
        exit 0
    fi
    
    validate_environment
}

handle_version() {
    echo "IMP (Implementation Management Platform) v$IMP_VERSION"
    exit 0
}

handle_uninstall() {
    if [ "$1" = "--help" ]; then
        echo "Usage: $0 uninstall"
        echo ""
        echo "Remove IMP from your system."
        echo ""
        echo "This command will:"
        echo "  1. Remove the IMP alias from your shell config"
        echo "  2. Delete the IMP installation directory"
        echo "  3. Remove any other IMP binaries found"
        echo "  4. Create backups of modified config files"
        exit 0
    fi
    
    # Get IMP directory (where this script is located)
    IMP_DIR=$(dirname "$(realpath "$0")")
    
    # Run the uninstall script
    "$IMP_DIR/uninstall.sh"
}

# Main function
main() {
    # Show help if no arguments provided
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi
    
    # Handle help flag
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_help
        exit 0
    fi
    
    # Check if first argument is a command or a spec file
    if [ "$1" = "init" ] || [ "$1" = "plan" ] || [ "$1" = "spawn" ] || [ "$1" = "finish" ] || [ "$1" = "status" ] || [ "$1" = "list" ] || [ "$1" = "check" ] || [ "$1" = "version" ] || [ "$1" = "uninstall" ]; then
        # It's a command, use the old routing
        COMMAND="$1"
        shift
        
        case "$COMMAND" in
            init)
                handle_init "$@"
                ;;
            plan)
                handle_plan "$@"
                ;;
            spawn)
                handle_spawn "$@"
                ;;
            finish)
                handle_finish "$@"
                ;;
            status)
                handle_status "$@"
                ;;
            list)
                handle_list "$@"
                ;;
            check)
                handle_check "$@"
                ;;
            version)
                handle_version "$@"
                ;;
            uninstall)
                handle_uninstall "$@"
                ;;
        esac
    else
        # It's a spec file, use the new spec-compliant flow
        handle_spec_file "$1"
    fi
}

# Run main function with all arguments
main "$@"