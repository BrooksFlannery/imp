# Development Notes

## v0.3.0 Roadmap

### Architecture Improvements
- [ ] Create constants file for version management (replace hardcoded "0.2.0" in multiple files)
- [ ] Replace agent creation of plan and phase files with script that parses analysis.json
- [ ] Use .json format over .txt format in phase files (for dependencies and domain)
- [ ] Add agent_domain section to phase plans for tracking file changes per agent

### Performance & Reliability
- [ ] Generate mermaid and phases files using bash script that parses analysis (faster, cheaper, more reliable)
- [ ] Experiment with timings and try to speed things up
- [ ] Automatically clean close active cursor tab when calling spawner

### Phase Management
- [ ] Fix phase item count - should have variable items per phase (2-12), not forced to 8
- [ ] Resolve naming inconsistency (letter suffix vs plain numbers)
- [ ] Make finish work with `<plan-file> <phase>` to match other args better

### Git Integration
- [ ] Track files changed in phase file for selective git updates
- [ ] Use agent_domain files to ensure git add only includes changes from specific agent
- [ ] System to automatically check if spec has been updated (currently need to delete imp-spec folder)

### Testing & Quality
- [ ] Test all imp.sh args thoroughly
- [ ] System only works with chats in panel view currently
- [ ] Clean up excessive logging output

### Technical Debt
- [ ] Lots of logs that make no sense need cleanup

## Implementation Notes

### Current Issues
- Version hardcoded in multiple files (imp.sh:38, imp-init.sh:115)
- Phase generation forces 8 items per phase
- Naming inconsistency between letter suffixes and plain numbers
- Git pushes include all changes, not just agent-specific changes

### Design Decisions
- Using markdown for phase files (considering JSON for structured data)
- Agent-based approach for plan generation (considering script-based parsing)
- Cursor integration for AI agent spawning

## Testing Strategy
- Test all command line arguments
- Verify phase dependency resolution
- Test git integration with selective file updates