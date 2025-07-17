# IMP (Implementation Management Platform)

A tool for managing software implementation projects using AI agents and structured workflows.

## Setup

### Option 1: One-Liner Installation (Recommended)

```bash
curl -sSL https://raw.githubusercontent.com/brooksflannery/imp/main/install-one-liner.sh | bash
```

This single command will:
- Clone the IMP repository to `~/.imp`
- Detect your shell (zsh/bash)
- Add the `imp` alias to your shell config
- Make IMP available immediately

### Option 2: Manual Installation

```bash
# Clone the repository
git clone https://github.com/brooksflannery/imp.git
# The clone creates a directory called "imp" - navigate into it
cd imp

# Run the installer
./install.sh
```

This will automatically:
- Detect your shell (zsh/bash)
- Add the `imp` alias to your shell config
- Validate the installation

## Usage

Once installed, you can use `imp` from any project directory:

```bash
# Initialize or continue implementation from a spec file
imp my-feature-spec.md

# Show help
imp --help

# Check version
imp version

# Check environment
imp check

# Uninstall IMP
imp uninstall
```

## How It Works

1. **Specification**: Start with a technical specification file (markdown)
2. **Analysis**: IMP analyzes the spec and generates an implementation plan
3. **Phases**: The plan is broken into phases with dependencies
4. **Agents**: AI agents are spawned to work on eligible phases
5. **Progress**: Track and manage implementation progress

## Example Workflow

```bash
# 1. Create a spec file
cat > my-feature.md << EOF
# My Feature Specification

## Overview
A simple feature that does X, Y, and Z.

## Requirements
- [ ] Requirement 1
- [ ] Requirement 2
- [ ] Requirement 3
EOF

# 2. Start implementation
imp my-feature.md

# 3. Check status
imp status .imp/imp-my-feature/imp-plan.md

# 4. Mark phases complete
imp finish "Phase 1: Setup" .imp/imp-my-feature
```

## Requirements

- **macOS** (for Cursor integration)
- **Git** repository (for tracking progress)
- **Cursor** (for AI agent spawning)
- **Basic shell tools**: jq, awk, sed, grep

## File Structure

```
imp/
├── imp.sh              # Main entry point
├── imp-init.sh         # Initialization script
├── imp-plan.sh         # Plan generation script
├── imp-spawner.sh      # Agent spawning script
├── imp-finish.sh       # Phase completion script
├── install.sh          # Installation script
├── uninstall.sh        # Uninstall script
├── install-one-liner.sh # One-liner installer
├── imp-agent.prompt    # Agent prompt template
├── imp-plan-prompt.txt # Plan generation prompt
└── README.md           # This file
```

## Troubleshooting

### "No such file or directory" error
Make sure you ran the installer or set up the alias correctly. The alias should point to the absolute path of `imp.sh`.

### "Not in a git repository" error
IMP requires a git repository to track progress. Initialize git in your project:
```bash
git init
```

### Cursor not found
Make sure Cursor is installed and accessible. IMP uses Cursor for AI agent spawning.

## Uninstalling

To remove IMP from your system:

```bash
imp uninstall
```

This will:
- Remove the `imp` alias from your shell config
- Delete the IMP installation directory (`~/.imp`)
- Remove any other IMP binaries found
- Create backups of modified config files

You can always reinstall later using the one-liner installation command.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) file for details. 