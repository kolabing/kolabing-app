# Mobile Refactor Command

Improve code quality without changing functionality.

## Input
- `$ARGUMENTS` - Description of refactoring to perform

## Usage Examples
```
/mobile-refactor Extract common widgets to shared package
/mobile-refactor Migrate state management to Riverpod
/mobile-refactor "Consolidate API service classes"
/mobile-refactor Improve error handling patterns
/mobile-refactor Split large screen into smaller widgets
```

## Execution Flow

### Phase 1: Task Creation
1. Create refactor task in `.agent/task/todo/refactor-<description>.md`
2. Document refactoring scope from `$ARGUMENTS`
3. Assign `@flutter-expert`

### Phase 2: Start Task
- Move task file from `todo/` to `inprogress/`
- Update task with start timestamp

### Phase 3: Analysis
Invoke `@flutter-expert` to:
- Analyze current code structure
- Identify files/components to refactor
- Document current vs proposed architecture
- Ensure no API contract changes
- Plan refactoring steps

### Phase 4: Refactoring
Invoke `@flutter-expert` to:
- Implement refactoring in small steps
- Maintain all existing functionality
- Preserve API contracts
- Update imports and references
- Ensure code compiles at each step

### Phase 5: Verification
- Verify all functionality preserved
- Run existing tests
- Document changes made

### Phase 6: Complete Task
- Move task file from `inprogress/` to `done/`
- Add completion timestamp

## Rules
- **No functionality changes** - Behavior must remain identical
- **No API contract changes** - Endpoints and models unchanged
- **Preserve architecture patterns** - Stay consistent with project
- **Incremental changes** - Small steps, always compilable
- **Document decisions** - Explain why changes were made

## Error Handling
- Log errors to `.agent/sop/`
- Task remains in `inprogress/` until resolved

## Agents
- `@flutter-expert` - Analysis and refactoring

## Task Template
```markdown
# Refactor: <description>

## Status
- Created: YYYY-MM-DD HH:MM
- Started: 
- Completed: 

## Refactoring Scope
$ARGUMENTS

## Current State
(analyze and document)

## Proposed Changes
(document plan)

## Affected Files
- 

## Changes Made
(to be filled during implementation)

## Verification
- [ ] All functionality preserved
- [ ] No API changes
- [ ] Code compiles
- [ ] Tests pass

## Notes

```

## Definition of Done
- [ ] Current state analyzed
- [ ] Refactoring plan documented
- [ ] Changes implemented
- [ ] Functionality verified unchanged
- [ ] Code compiles without errors
- [ ] Task moved to `done/`
