# Global Development Rules

## Strict Red-Green-Refactor TDD

Every feature, bug fix, or behavioral change follows this cycle without exception.

### RED
1. Write exactly one failing test before any production code.
2. Run it. Confirm it fails because the behavior is missing, not because of a
   syntax or setup error.
3. Do not proceed until you have seen it fail.

### GREEN
1. Write the minimum production code to make the failing test pass.
2. Run the affected tests. They must all pass.
3. Do not add behavior that no test demands.

### REFACTOR
1. Improve structure in both test and production code.
2. Run the affected tests after each change.
3. If any test fails, revert the refactoring -- never fix the test to match.

### Cycle Discipline
- One test at a time. Never write multiple failing tests before implementing.
- When fixing a bug, write a failing test that reproduces it first.
- Never modify a test to make it pass. Fix the implementation.
- Use triangulation: if the simplest passing implementation is a hardcoded
  return value, add a second test with different inputs to force the general
  solution.
- Run the full suite only at the end, before considering the work complete.

## Design Principles

### Fail fast
- Reject invalid state at the earliest possible moment. Validate inputs at
  system boundaries -- configuration, API entry points, deserialization.
- Reject unexpected fields rather than silently ignoring them.
- Make invalid state unrepresentable through the type system, validated
  constructors, or startup-time checks.
- Prefer crashes over silent corruption.

### Type everything, mutate nothing
- Annotate every binding with its type.
- Default to immutability. Mutable state requires justification.
- Configuration and data transfer objects should be frozen.

### Real infrastructure over mocks
- Test against real databases, brokers, and services whenever possible.
- Only mock what cannot run locally.
- When a dependency must be controlled, swap it at the injection boundary.
  Never patch internals.

### Contracts over inheritance
- Define dependencies as interfaces or protocols.
- Compose behavior through small functions and factories, not deep class
  hierarchies.

### Explicit over clever
- No wildcard imports.
- No bare exception handlers.
- No monkey-patching in production code.

### Self-documenting with rare surgical comments
- Lean on types and descriptive names, not comments.
- Document contracts (inputs, outputs, errors). Skip the obvious.
- Comments explain why, never what.

## Testing Style

### Organization
- Mirror the source tree in the test directory.
- Nest test classes to form a scenario tree: the class name is the
  precondition, the method name is the assertion.

### Boundaries
- Test boundary conditions with minimal deltas -- one unit above, one unit
  below, exactly on the line.
- Give parameterized cases semantic names, not anonymous tuples.

### Simplicity
- Use the language's plainest assertion. No custom helpers.
- Default to no mocks. Swap at the injection boundary when control is needed.
- Identify the test runner before writing the first test.
