# Mobile Tasks Command

Main workflow command for mobile app development from API integration file.

## Input
- `$ARGUMENTS` - Path to API integration file (required)

## Execution Flow

### Phase 1: API Analysis
1. Read and parse the API integration file at `$ARGUMENTS`
2. Extract all endpoints (method, path, request/response)
3. Extract data models and their relationships
4. Identify screens/features needed based on endpoints
5. Determine task dependencies and execution order

### Phase 2: Task Creation
For each identified feature:
1. Create task file in `.agent/task/todo/<feature-name>.md`
2. Include:
   - Feature description
   - Related API endpoints
   - Data models required
   - Dependencies on other tasks
   - Assigned agents: `@ux-designer`, `@flutter-expert`

### Phase 3: Task Execution Loop
For each task (in dependency order):

**3.1 Start Task**
- Move task file from `todo/` to `inprogress/`
- Update task with start timestamp

**3.2 UX Design Phase**
Invoke `@ux-designer` to:
- Define user flow for the feature
- Create wireframe/mockup specifications
- Specify UI components needed
- Define states: loading, error, empty, success
- Define interactions and animations
- Update task file with UX specs

**3.3 Flutter Implementation Phase**
Invoke `@flutter-expert` to:
- Implement screens/widgets based on UX specs
- Create Dart data models from API response
- Implement API service/repository layer
- Setup state management
- Handle all UI states
- Implement error handling
- Update task file with implementation details

**3.4 Complete Task**
- Move task file from `inprogress/` to `done/`
- Add completion timestamp
- Proceed to next task

### Phase 4: Documentation
- Generate final summary of all completed tasks
- Create architecture overview
- Document API integration map

## Error Handling
- Log errors to `.agent/sop/` as markdown files
- Task remains in `inprogress/` until resolved

## Agents
- `@ux-designer` - UI/UX design, user flows, components, states
- `@flutter-expert` - Flutter implementation, state management, API integration

## Task Template
```markdown
# Task: <feature-name>

## Status
- Created: YYYY-MM-DD HH:MM
- Started: 
- Completed: 

## Description
<feature description>

## Related API Endpoints
- [ ] METHOD /endpoint

## Data Models
\`\`\`dart
// To be defined
\`\`\`

## Dependencies
- Depends on: 
- Blocks: 

## Assigned Agents
- [ ] @ux-designer
- [ ] @flutter-expert

## Progress

### UX Design
**Status:** Pending
- User Flow: 
- UI Components: 
- States: 
- Interactions: 

### Flutter Implementation
**Status:** Pending
- Screens: 
- Widgets: 
- State Management: 
- API Integration: 

## Notes

```

## Definition of Done
- [ ] API file analyzed
- [ ] All tasks created
- [ ] All agents invoked for each task
- [ ] All tasks moved to `done/`
- [ ] Documentation generated
