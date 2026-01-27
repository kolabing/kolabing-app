# Mobile UI Command

UI-only tasks without API integration.

## Input
- `$ARGUMENTS` - Description of UI component or screen to create

## Usage Examples
```
/mobile-ui Splash screen animation
/mobile-ui Custom loading indicators
/mobile-ui "Onboarding carousel screens"
/mobile-ui Bottom sheet component
/mobile-ui Empty state illustrations
/mobile-ui App theme and color system
```

## Execution Flow

### Phase 1: Task Creation
1. Create UI task in `.agent/task/todo/ui-<description>.md`
2. Document UI requirements from `$ARGUMENTS`
3. Assign agents: `@ui-designer`, `@brand-designer`, `@flutter-expert`

### Phase 2: Start Task
- Move task file from `todo/` to `inprogress/`
- Update task with start timestamp

### Phase 3: UX Design
Invoke `@ui-designer` to:
- Define visual specifications
- Create component design
- Specify:
  - Layout and dimensions
  - Colors and typography
  - Animations and transitions
  - Responsive behavior
  - Accessibility considerations
- Document interaction patterns
- Update task file with design specs

### Phase 4: Flutter Implementation
Invoke `@flutter-expert` to:
- Implement widget/screen based on design
- Create reusable components
- Implement animations
- Handle different screen sizes
- Ensure accessibility
- Update task file with implementation details

### Phase 5: Complete Task
- Move task file from `inprogress/` to `done/`
- Add completion timestamp

## Scope
- **No API integration** - Pure UI/UX work
- **Reusable components** - Build for reusability
- **Design system aligned** - Follow existing patterns
- **Accessible** - Consider a11y requirements

## Error Handling
- Log errors to `.agent/sop/`
- Task remains in `inprogress/` until resolved

## Agents
- `@ui-designer` - Visual design and specifications
- `@brand-designer` - Brand identity, colors, typography decisions
- `@flutter-expert` - Widget implementation

## Task Template
```markdown
# UI: <description>

## Status
- Created: YYYY-MM-DD HH:MM
- Started: 
- Completed: 

## UI Requirements
$ARGUMENTS

## Design Specifications

### Layout
(to be filled by @ui-designer)

### Colors & Typography
(to be filled)

### Animations
(to be filled)

### Responsive Behavior
(to be filled)

### Accessibility
(to be filled)

## Implementation

### Widget Structure
(to be filled by @flutter-expert)

### Files Created
- 

### Usage Example
\`\`\`dart
// How to use this component
\`\`\`

## Notes

```

## Definition of Done
- [ ] Design specifications completed
- [ ] Widget/screen implemented
- [ ] Animations working
- [ ] Responsive on different screens
- [ ] Accessible
- [ ] Code compiles without errors
- [ ] Task moved to `done/`
