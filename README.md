# imp - Cursor Implementation Tool

## imp is a tool that automatically implements project specifications by spawning cursor AI agents to work on different phases of your project.

### 1. Setup

```bash
# Create a bin directory in your home folder
mkdir -p ~/bin

# Create the imp wrapper script
cat > ~/bin/imp << 'EOF'
#!/bin/bash
cd /Users/brooksflannery/Documents/GitHub/cursor-global
./spawner.sh "$@"
EOF

chmod +x ~/bin/imp

# Add ~/bin to your PATH
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### 2. Format your spec files

Create a `.mdx` file with your project phases and tasks:

```markdown

### Phase 1: Setup
- [ ] Create project structure
- [ ] Set up dependencies

### Phase 2a: Backend
- [ ] Create API endpoints
- [ ] Set up database

### Phase 2b: Frontend
- [ ] Build UI components
- [ ] Connect to API

### Phase 3: Deploy
- [ ] Test everything
- [ ] Deploy to production
```

### 3. Run imp

```bash
imp "my-project.mdx"
```

That's it! `imp` will automatically:
- Detect which phases are ready to run
- Spawn AI agents for each phase
- Have agents work through tasks and mark them complete
- Move to the next phase when ready

## How it works

### Phase numbering
- **Sequential phases** (1, 2, 3): Must complete in order
- **Parallel phases** (2a, 2b, 2c): Can run at the same time
- **Dependencies**: All Phase X* subphases must finish before Phase X+1

### What happens
1. `imp` reads your spec file
2. Finds incomplete phases that are ready to run
3. Opens Cursor chat tabs for each phase
4. AI agents work through tasks, marking them `[x]` when done
5. When a phase completes, the next phase starts automatically

### Manual control
```bash
# Run specific phases
imp "project.mdx" "Phase 2a: Backend" "Phase 2b: Frontend"
```

## Requirements

- macOS
- Cursor (AI code editor)
- Terminal accessibility permissions

## Troubleshooting

- **"Script not executable"**: Run `chmod +x ~/bin/imp`
- **"Cursor not found"**: Make sure Cursor is installed
- **"Permission denied"**: Grant Terminal accessibility permissions

## Notes
- Concurrent phases block each others ability to edit the spec doc.

That's all you need to know! Just write your spec and run `imp`.
