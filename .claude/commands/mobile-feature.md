# Mobile Feature Command

Develop a single mobile feature with specified API endpoints.

## Input
- `$ARGUMENTS` - Feature name and optional API endpoint reference

## Usage Examples
```
/mobile-feature User Profile Screen --api="/users/{id}"
/mobile-feature Product List
/mobile-feature "Shopping Cart" --api="/cart, /cart/items"
```

## Execution Flow

### Phase 1: Task Creation
1. Create task file in `.agent/task/todo/<feature-name>.md`
2. Parse API endpoint from arguments if provided
3. Define feature scope and requirements
4. Set assigned agents: `@ux-designer`, `@flutter-expert`

### Phase 2: Start Task
- Move task file from `todo/` to `inprogress/`
- Update task with start timestamp

### Phase 3: UX Design
Invoke `@ux-designer` to:
- Define user flow for the feature
- Create component specifications
- Define all UI states:
  - [ ] Loading state
  - [ ] Empty state
  - [ ] Error state
  - [ ] Success state
- Specify interactions and animations
- Update task file with design specs

### Phase 4: Flutter Implementation
Invoke `@flutter-expert` to:
- Create screen/widget files
- Implement data models
- Setup API service layer
- Implement state management
- Handle all defined states
- Add error handling
- Update task file with implementation details

### Phase 5: Complete Task
- Move task file from `inprogress/` to `done/`
- Add completion timestamp

## Error Handling
- Log errors to `.agent/sop/`
- Task remains in `inprogress/` until resolved

## Agents
- `@ux-designer` - Design specifications
- `@flutter-expert` - Implementation

## Definition of Done
- [ ] UX design completed
- [ ] Flutter implementation completed
- [ ] All UI states handled
- [ ] Code compiles without errors
- [ ] Task moved to `done/`
