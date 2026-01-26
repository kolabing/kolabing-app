# Mobile Fix Command

Fix an existing bug or issue in the mobile app.

## Input
- `$ARGUMENTS` - Description of the bug/issue to fix

## Usage Examples
```
/mobile-fix Bottom navigation not highlighting active tab
/mobile-fix Login button not responding on iOS
/mobile-fix "Image not loading in product detail screen"
/mobile-fix Keyboard overlapping input fields
```

## Execution Flow

### Phase 1: Task Creation
1. Create fix task in `.agent/task/todo/fix-<issue-name>.md`
2. Document the issue description from `$ARGUMENTS`
3. Set assigned agents based on issue type

### Phase 2: Start Task
- Move task file from `todo/` to `inprogress/`
- Update task with start timestamp

### Phase 3: Diagnosis
Invoke `@flutter-expert` to:
- Analyze the issue
- Identify root cause
- Document affected files/components
- Propose fix approach

### Phase 4: Fix Implementation
Invoke `@flutter-expert` to:
- Implement minimal fix
- Ensure no side effects
- Test the fix

If UI changes are needed, invoke `@ux-designer` to:
- Review UI impact
- Provide updated design specs if necessary

### Phase 5: Complete Task
- Move task file from `inprogress/` to `done/`
- Add completion timestamp
- Document the fix applied

## Rules
- **Minimal changes only** - Fix the issue, don't refactor
- **No scope creep** - Stay focused on the reported issue
- **Document root cause** - Help prevent similar issues

## Error Handling
- Log errors to `.agent/sop/`
- Task remains in `inprogress/` until resolved

## Agents
- `@flutter-expert` - Diagnosis and fix (primary)
- `@ux-designer` - Only if UI changes needed

## Task Template
```markdown
# Fix: <issue-description>

## Status
- Created: YYYY-MM-DD HH:MM
- Started: 
- Completed: 

## Issue Description
$ARGUMENTS

## Root Cause
(to be filled by @flutter-expert)

## Affected Files
- 

## Fix Applied
(to be filled)

## Testing
- [ ] Issue no longer occurs
- [ ] No side effects introduced
- [ ] Code compiles

## Notes

```

## Definition of Done
- [ ] Root cause identified
- [ ] Fix implemented
- [ ] Issue verified as resolved
- [ ] No new issues introduced
- [ ] Task moved to `done/`
