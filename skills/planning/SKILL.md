---
name: planning
description: Collaborative work decomposition into parallelizable Jira stories with acceptance criteria and dependency links
---

# Planning Skill

## Purpose

Decompose high-level work into small, well-scoped Jira stories that can be
executed in parallel by autonomous agents in separate git worktrees. The output
is a structured plan for human review before Jira issue creation.

## Workflow

### Phase 1: Understand the Goal

1. Ask the user for the high-level objective if not already provided.
2. Identify the project key (e.g., `ITPART`) -- never assume it.
3. Explore the codebase using the Task tool with the `explore` agent to
   understand the relevant modules, files, classes, and interfaces. Do NOT
   skip this step -- the quality of the plan depends on concrete knowledge
   of what exists in the code.
4. Check for existing related Jira issues to avoid duplication and to
   understand prior work. Use `jira_jira_search` with relevant keywords.

### Phase 2: Decompose into Stories

Break the work into the smallest independently-deliverable stories. Each story
must satisfy ALL of these constraints:

#### Scope Rules

- **One concern per story.** A story touches one logical unit: a single
  consumer, a single endpoint, a single migration, a single configuration
  change. If you need "and" to describe it, split it.
- **Minimize file overlap.** Two stories that will run in parallel must not
  modify the same files. When overlap is unavoidable, create a dependency
  between them so they run sequentially.
- **Interface-first.** If parallel stories depend on a shared interface,
  type, or contract, create a prerequisite story that defines that interface.
  The parallel stories then depend on it.
- **Test scope is part of the story.** Each story includes writing or
  updating the tests for the behavior it adds, modifies, or removes. Tests
  are not a separate story.

#### Sizing Rules

- A story should be completable in a single focused session (roughly 1-4
  hours of autonomous agent work).
- If a story requires understanding more than ~5 files in depth, it is
  probably too large. Split it.
- If a story has more than 6 acceptance criteria bullets, consider whether
  it can be split.

### Phase 3: Identify Dependencies

For each story, determine:

1. **What must exist before this story can start?** These are `depends on`
   links.
2. **What does this story block?** These are `blocks` links.
3. **Which stories can run in parallel?** Stories with no dependency
   relationship between them.

Organize stories into **lanes** -- groups that can execute concurrently.
Present the dependency structure as a visual DAG when possible:

```
Lane 1:  [A] ──> [D] ──> [G]
Lane 2:  [B] ──> [E] ──┐
Lane 3:  [C] ──────────> [F] ──> [H]
```

Where `[X] ──> [Y]` means Y depends on X.

### Phase 4: Write Acceptance Criteria

Each story's acceptance criteria must be specific enough for an autonomous
agent to execute without human clarification. Follow this template:

```
* <Concrete code change: what class/file/config to modify and how>
* <Behavioral requirement: what the system does after the change>
* <Scope boundary: what is explicitly NOT modified>
* <Test requirement: which tests to add/modify/remove, with specific
  annotations, flags, or configuration>
* All tests pass
* No regressions in <affected functionality>
```

#### Acceptance Criteria Quality Checklist

- [ ] References specific classes, files, or configuration keys by name
- [ ] States what changes AND what stays the same
- [ ] Specifies test expectations (new tests, modified tests, removed tests)
- [ ] Mentions environment-specific behavior if applicable
- [ ] An agent with codebase access could execute this without asking
      clarifying questions

### Phase 5: Label for Execution Mode

Apply one of these labels to each story:

- `agent-eligible` -- The story is well-scoped, has clear acceptance
  criteria, and can be executed autonomously by an agent. The changes are
  mechanical or follow established patterns in the codebase.
- `human-required` -- The story requires judgment calls, architectural
  decisions, external coordination, or changes that are too risky for
  autonomous execution. Examples: security-sensitive changes, API contract
  changes visible to external consumers, infrastructure provisioning.

When in doubt, label as `human-required`. It is safer to have a human
handle ambiguous work than to have an agent make wrong assumptions.

### Phase 6: Present the Plan for Review

Present the complete plan to the user in this format BEFORE creating any
Jira issues:

```
## Plan: <High-Level Objective>

### Dependency Graph
<ASCII DAG showing lanes and dependencies>

### Stories

#### 1. <Summary>
- **Type:** Story
- **Label:** agent-eligible | human-required
- **Depends on:** <list of story numbers or "none">
- **Blocks:** <list of story numbers or "none">
- **Description:** <1-2 sentences of context>
- **Acceptance Criteria:**
  * <bullet 1>
  * <bullet 2>
  * ...

#### 2. <Summary>
...
```

Wait for the user to:
- Approve the plan as-is
- Request modifications (reorder, split, merge, re-scope stories)
- Add or remove stories
- Change labels

Do NOT proceed to Jira issue creation until the user explicitly approves.

### Phase 7: Create Jira Issues

Once approved, create the issues in dependency order (prerequisites first)
so that issue keys are available for linking:

1. Create stories with no dependencies first.
2. For each story, set:
   - `summary` -- from the plan
   - `description` -- from the plan
   - `issue_type` -- `Story` (unless the user specifies otherwise)
   - `customfield_12315940` (Acceptance Criteria) -- from the plan
   - `labels` -- `agent-eligible` or `human-required`
3. After all stories are created, add dependency links:
   - Use link type `Depend` (id: `12311220`) for `depends on` relationships
   - Use link type `Blocks` (id: `12310720`) for `blocks` relationships
4. If the stories belong under an Epic, use `jira_jira_link_to_epic` to
   link them.
5. Present the created issue keys to the user with their dependency
   structure.

## Jira Field Reference

| Field               | ID                      | Usage                          |
|---------------------|-------------------------|--------------------------------|
| Acceptance Criteria | `customfield_12315940`  | Textarea, bullet-point list    |
| Link: Depends on    | type id `12311220`      | DAG edges for prerequisites    |
| Link: Blocks        | type id `12310720`      | Hard ordering constraints      |
| Link: Issue split   | type id `12311720`      | Traceability from decomposition|
| Link: Related       | type id `12310001`      | Informational cross-references |

## Anti-Patterns to Avoid

| Anti-Pattern | Why It Is Harmful | What to Do Instead |
|---|---|---|
| Stories that share modified files | Causes merge conflicts in parallel execution | Split along file boundaries or add dependency links |
| Vague acceptance criteria ("update tests") | Agent cannot execute without clarification | Name specific test classes, annotations, and assertions |
| Monolithic stories | Too large for a single agent session, hard to parallelize | Split into smallest independently-deliverable units |
| Missing scope boundaries | Agent may modify code outside its lane | Explicitly state what is NOT changed |
| Skipping codebase exploration | Plan is based on assumptions, not reality | Always explore before decomposing |
| Creating issues before approval | User loses control of the plan | Always present and wait for explicit approval |
| All stories in a single lane | No parallelism, defeats the purpose | Maximize independent lanes through interface-first design |
| Labeling ambiguous work as agent-eligible | Agent makes wrong assumptions, produces bad code | Default to human-required when uncertain |
