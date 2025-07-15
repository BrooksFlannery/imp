# Cursor Global Implementation Workflow

This repository contains a powerful workflow system that combines Cursor's AI capabilities with automated agent spawning to handle complex implementation tasks across multiple phases.

## Overview

The system consists of three main components:
1. **Cursor Rules** - Custom rules that define AI agent behaviors
2. **Spawner Script** - Automated agent spawning and coordination
3. **Specification Files** - Structured task definitions with phases and checklists

## Quick Start

### 1. Setup Cursor Rules

Add these rules to your Cursor settings (`.cursorrules` file):

```yaml
---
description: Spawn implementation agents to work on spec phases
manualInvocation: ["spawn_agents"]
alwaysApply: false
---

You are a spawner agent. When this rule is triggered:
- Read the specified spec file
- Find the next incomplete phases
- For parallel phases (2a, 2b, 2c), collect all incomplete ones
- For sequential phases, collect the next incomplete one
- Call: ./spawner.sh "{spec_file}" "{phase_name1}" "{phase_name2}" "{phase_name3}" ...

For phase selection:
- Skip phases that are already complete (all tasks marked [x])
- For parallel phases (2a, 2b, 2c), spawn all incomplete ones together
- For sequential phases, spawn the next incomplete one
- Ensure all prerequisite phases are complete before moving to next numbered phase

---
description: Implementation agent for checklists
manualInvocation: ["start-implementation-agent"]
alwaysApply: false
---

You are an implementation agent. When this rule is triggered:
- Read the specified spec file
- Find your assigned phase
- Work through each task in that phase, marking them as complete [x] as you go
- Update the spec file DIRECTLY after each task
- When finished, find the next phase and call: ./spawner.sh "{spec_file}" "{next_phase_name}"

For each task:
- If already marked complete [x], skip it
- If not complete [ ], work on it and mark it complete when finished
- Do not describe - just do the work
```

### 2. Make Spawner Script Executable

```bash
chmod +x spawner.sh
```

### 3. Create a Specification File

Create a `.mdx` file with your project phases and tasks:

```markdown
# Project Name

## 5. Phases & Tasks

### Phase 1: Setup & Planning
- [ ] Define schema contracts
- [ ] Set up initial GitHub issue/project board

### Phase 2a: Backend Development
- [ ] Create API endpoints
- [ ] Implement database models

### Phase 2b: Frontend Development
- [ ] Build user interface components
- [ ] Integrate with backend APIs

### Phase 2c: Testing Infrastructure
- [ ] Set up unit test framework
- [ ] Create integration test suite

### Phase 3: Integration & Deployment
- [ ] End-to-end testing
- [ ] Deploy to staging environment
```

## How It Works

### Phase Numbering System

The system uses a structured numbering scheme:

- **Sequential Phases**: Use whole numbers (1, 2, 3...) for phases that must run in order
- **Parallel Phases**: Use letter suffixes (2a, 2b, 2c...) for phases that can run simultaneously
- **Dependencies**: All Phase X* subphases must complete before moving to the next numbered phase

### Workflow Process

1. **Spawner Agent**: Triggered manually with `spawn_agents`
   - Reads the spec file
   - Identifies incomplete phases
   - Spawns implementation agents for each phase

2. **Implementation Agents**: Automatically spawned for each phase
   - Work through tasks in their assigned phase
   - Mark tasks as complete [x] when finished
   - Update the spec file directly
   - Automatically spawn the next phase when done

3. **Automation**: The spawner script uses AppleScript to:
   - Open new Cursor chat tabs
   - Set the clipboard with agent prompts
   - Automatically submit the prompts

## Usage Examples

### Starting a New Project

1. Create your spec file (e.g., `my-project.mdx`)
2. In Cursor, type: `spawn_agents`
3. The spawner will automatically start Phase 1

### Manual Phase Control

```bash
# Spawn specific phases
./spawner.sh "my-project.mdx" "Phase 2a: Backend Development" "Phase 2b: Frontend Development"

# Spawn next sequential phase
./spawner.sh "my-project.mdx" "Phase 3: Integration & Deployment"
```

### Monitoring Progress

- Check `spawner.log` for detailed execution logs
- Monitor your spec file for task completion status
- Each agent updates the spec file in real-time

## File Structure

```
cursor-global/
├── spawner.sh                    # Main automation script
├── implementation_agent_prompt.txt # Agent prompt template
├── spawner.log                   # Execution logs
├── test-spec.mdx                 # Example specification
└── README.md                     # This file
```

## Requirements

- **macOS**: The spawner script uses AppleScript for Cursor automation
- **Cursor**: Must be installed and accessible
- **Bash**: For script execution
- **Permissions**: Script needs clipboard and system event access

## Known Limitations & Future Improvements

### Current Hurdles

1. **Old Chat Interference**: Existing Cursor chat sessions can block new spawned chats from working properly
   - **Potential Solution**: Implementing Git workflow integration may resolve this by providing better state management
   - **Workaround**: Manually close old chat tabs before spawning new agents

2. **Concurrent Edit Conflicts**: Multiple agents running in parallel can conflict when editing the same spec file simultaneously
   - **Impact**: Agents may overwrite each other's changes or fail to update the spec file
   - **Current Workaround**: Use sequential phases (1, 2, 3) instead of parallel phases (2a, 2b, 2c) for critical sections
   - **Future Solution**: Implement file locking or Git-based coordination

### Recommended Workflow

Until these issues are resolved:
- **For critical phases**: Use sequential execution to avoid edit conflicts
- **For independent work**: Use parallel phases but monitor for conflicts
- **Before spawning**: Clear old chat tabs to prevent interference

## Troubleshooting

### Common Issues

1. **Script not executable**: Run `chmod +x spawner.sh`
2. **Cursor not found**: Ensure Cursor is installed and in your PATH
3. **Permission denied**: Grant accessibility permissions to Terminal/your shell
4. **Clipboard issues**: Check if another app is controlling the clipboard
5. **Chat conflicts**: Close old chat tabs before spawning new agents
6. **File edit conflicts**: Use sequential phases for critical spec updates

### Parallel vs Sequential Execution

- **Parallel phases** (2a, 2b, 2c): All spawn simultaneously
- **Sequential phases** (1, 2, 3): Spawn one at a time
- **Mixed workflows**: Combine both for complex projects

### Integration with Other Tools

- **Git**: Agents can commit changes automatically
- **CI/CD**: Use spec completion as deployment triggers
- **Project Management**: Sync with GitHub Issues, Jira, etc.

## Best Practices

1. **Clear Phase Names**: Use descriptive phase names for better tracking
2. **Granular Tasks**: Break down phases into small, manageable tasks
3. **Dependencies**: Ensure proper phase ordering with numbered sequences
4. **Documentation**: Keep spec files updated with current progress
5. **Backup**: Version control your spec files for rollback capability
