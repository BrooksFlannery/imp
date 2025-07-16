# IMP (Implementation Management Platform) Technical Specification

## 1. Overview

IMP is an automated project implementation system that manages multi-phase technical specifications through intelligent agent orchestration. The system takes a technical specification as input, analyzes the current project state, creates a structured implementation plan with Mermaid flowcharts, and automatically spawns Cursor agents to work on eligible phases while maintaining proper isolation and git workflow management.

**Key Features:**
- Automated spec analysis and phase dependency resolution
- Mermaid-based visual progress tracking with status classes
- Git branch isolation per phase with user approval workflow
- Concurrent phase execution with race condition prevention
- Single source of truth state management via Mermaid diagram

## 2. Architecture Diagram

```mermaid
graph LR
    User[User Terminal] -->|imp spec.md| Main[imp.sh]
    Main -->|Check exists| Decision{IMP repo exists?}
    Decision -->|No| Init[imp-init.sh]
    Decision -->|Yes| Spawner[imp-spawner.sh]
    Init -->|Creates| Dir[.imp/imp-specname/]
    Init -->|Calls| SpecAgent[Spec Analysis Agent]
    SpecAgent -->|Analyzes| Spec[spec.md]
    SpecAgent -->|Creates| Analysis[analysis.json]
    SpecAgent -->|Calls| PlanAgent[Plan Generation Agent]
    PlanAgent -->|Creates| Plan[plan.json]
    PlanAgent -->|Calls| MermaidAgent[Mermaid Generation Agent]
    MermaidAgent -->|Creates| Diagram[imp-plan.md]
    MermaidAgent -->|Calls| PhaseAgent[Phase File Generator]
    PhaseAgent -->|Creates| Phases[phase-*.md files]
    PhaseAgent -->|Calls| Spawner
    Spawner -->|Parses| Diagram
    Spawner -->|Spawns| Agent[Cursor Agent]
    
    Agent -->|Updates| PhaseFile[phase-*.md checklist]
    Agent -->|Tells user| Finish[imp-finish.sh]
    Finish -->|Git operations| Git[Git Repository]
    Finish -->|Updates| Diagram
    Finish -->|Calls| Spawner
```

## 3. API / Protocol

### Script Interfaces

#### imp.sh
```bash
imp.sh <spec-file-path>
```
- Main entry point script
- Checks if IMP repository already exists
- If exists: calls imp-spawner.sh directly
- If not exists: calls imp-init.sh (which then calls imp-spawner.sh)
- Returns: 0 on success, 1 on failure

#### imp-init.sh
```bash
imp-init.sh <spec-file-path>
```
- Creates .imp directory if it doesn't exist
- Creates imp-specname subdirectory based on spec filename
- Spawns spec analysis agent to analyze spec and project state
- Returns: 0 on success, 1 on failure

#### imp-spawner.sh
```bash
imp-spawner.sh
```
- Parses imp-plan.md Mermaid diagram
- Identifies phases with `incomplete` status whose dependencies are `complete`
- Spawns Cursor agents for eligible phases
- Updates phase status to `inProgress` in Mermaid diagram
- Returns: 0 on success, 1 on failure

#### imp-finish.sh
```bash
imp-finish.sh <phase-name>
```
- Creates git branch: imp/phase-name
- Commits phase changes
- Pushes to remote
- Updates phase status from `inProgress` to `complete` in imp-plan.md
- Calls imp-spawner.sh to spawn new eligible phases
- Returns: 0 on success, 1 on failure

### Mermaid Status Classes
- `:::incomplete` - Phase not started (default state)
- `:::inProgress` - Phase currently being worked on
- `:::complete` - Phase finished and approved
- `:::failed` - Phase failed (unused for now)

### Cursor Agent Spawning System
The IMP system uses a sophisticated agent spawning mechanism to automate Cursor IDE interactions:

#### Agent Prompt Template (`implementation_agent_prompt.txt`)
- Template-based prompts with variable substitution
- Uses `{SPEC_NAME}` and `{PHASE_NAME}` placeholders
- Provides clear instructions for agent behavior and completion workflow

#### Spawner Script (`spawner.sh`)
- Uses AppleScript to automate Cursor IDE
- Creates new chat tabs programmatically
- Sets clipboard with customized agent prompts
- Supports both manual phase specification and automatic phase detection
- Handles multiple concurrent agents with proper timing

#### Key Features:
- **Dynamic Prompt Generation**: Substitutes variables in prompt templates
- **Automated Cursor Control**: Uses `osascript` to control Cursor IDE
- **Clipboard Integration**: Uses `pbcopy`/`pbpaste` for prompt transfer
- **Concurrent Agent Management**: Spawns multiple agents in separate tabs
- **Phase Detection**: Can automatically detect incomplete phases
- **Logging**: Comprehensive logging for debugging and monitoring

## 4. Phases & Tasks

### Phase 1: Basic Initialization ✅
- [x] Create imp-init.sh with directory creation logic
- [x] Implement .imp directory creation if not exists
- [x] Create imp-specname subdirectory based on spec filename
- [x] Add basic error handling and validation
- [x] Ensure proper exit codes (0 success, 1 failure)
- [x] Add logging for directory operations
- [x] Validate spec file exists and is readable
- [x] Create basic directory structure template

### Phase 2: Spec Analysis Agent System ✅
- [x] Create spec-analysis-agent.sh spawning logic
- [x] Implement agent prompt generation for spec analysis
- [x] Add spec file parsing and content extraction
- [x] Create project state analysis agent prompts
- [x] Implement diff generation between current and desired state
- [x] Add agent result parsing and validation
- [x] Create analysis output format specification
- [x] Add error handling for agent failures

### Phase 3: Implementation Plan Generation
- [ ] Create plan-generation-agent.sh spawning logic
- [ ] Implement analysis-to-plan conversion logic
- [ ] Add phase dependency resolution algorithm
- [ ] Create concurrent phase detection and grouping
- [ ] Implement phase granularity optimization
- [ ] Add plan validation and completeness checking
- [ ] Create plan output format (JSON/YAML)
- [ ] Add plan versioning and metadata

### Phase 4: Mermaid Diagram Generation
- [ ] Create mermaid-generation-agent.sh spawning logic
- [ ] Implement plan-to-mermaid conversion
- [ ] Add dependency graph visualization
- [ ] Create status class assignment (incomplete by default)
- [ ] Implement phase node generation with proper IDs
- [ ] Add edge creation for dependencies
- [ ] Create diagram validation and formatting
- [ ] Add diagram versioning and update mechanisms

### Phase 5: Phase File Creation
- [ ] Create phase-file-generator.sh spawning logic
- [ ] Implement plan-to-phase-files conversion
- [ ] Add phase file template system
- [ ] Create naming convention: "phase-number-phase-title.md"
- [ ] Implement checklist generation from plan tasks
- [ ] Add phase metadata and dependencies
- [ ] Create phase file validation
- [ ] Add phase file versioning

### Phase 6: Spawner Implementation
- [ ] Create imp-spawner.sh core spawning logic
- [ ] Implement Mermaid parsing with regex
- [ ] Add dependency resolution algorithm
- [ ] Create phase eligibility checking
- [ ] Implement status class updates
- [ ] Add concurrent phase safety checks
- [ ] Create Cursor agent spawning
- [ ] Add agent prompt generation

### Phase 7: Git Integration System
- [ ] Create imp-finish.sh git operations
- [ ] Implement branch creation logic
- [ ] Add change detection and staging
- [ ] Create commit message generation
- [ ] Implement push to remote
- [ ] Add conflict detection
- [ ] Create rollback mechanisms
- [ ] Add git status validation

### Phase 8: User Interface Integration
- [ ] Create Cursor UI approval dialog
- [ ] Implement change summary generation
- [ ] Add approval workflow integration
- [ ] Create progress visualization
- [ ] Implement real-time status updates
- [ ] Add manual phase management
- [ ] Create error reporting interface
- [ ] Add user preference configuration

### Phase 9: Testing and Validation
- [ ] Create unit tests for all scripts
- [ ] Implement integration test suite
- [ ] Add Mermaid parsing validation
- [ ] Create git workflow testing
- [ ] Implement agent isolation testing
- [ ] Add concurrent execution testing
- [ ] Create error scenario testing
- [ ] Add performance benchmarking

## 5. Deployment

### Prerequisites
- Git repository with remote configured
- Cursor IDE with agent capabilities
- Bash shell environment
- Read/write permissions for IMP directories

### Installation
1. Clone IMP repository to local machine
2. Set up git remote configuration
3. Test with sample specification
4. Configure Cursor agent permissions

## 6. Success Criteria

### Functional Requirements
- [ ] Successfully analyze spec and create implementation plan
- [ ] Automatically spawn agents for eligible phases
- [ ] Maintain proper git branch isolation per phase
- [ ] Update Mermaid diagrams with correct status classes
- [ ] Handle concurrent phase execution without conflicts
- [ ] Provide user approval workflow for phase completion
- [ ] Support both sequential and parallel phase dependencies

### Quality Requirements
- [ ] Zero data loss during phase transitions
- [ ] 99% accuracy in dependency resolution
- [ ] Proper error handling for all failure scenarios
- [ ] Clear logging for debugging and monitoring
- [ ] User-friendly error messages and recovery options
