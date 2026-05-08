---
name: plan-on-demand
description: Before any multi-step work, assess whether a plan.md is needed. Creates plan.md only for tasks with sufficient complexity. Skips for trivial/single-step tasks.
---

# Plan on Demand

Decide whether a task needs a written plan (`plan.md`). Not everything does.

## Decision Tree

For ANY new task, run this before touching code:

```
Task arrives
  │
  ├─ Is it a single-step task? (one file edit, one command, trivial config change)
  │     → SKIP plan, just do it
  │
  ├─ Are steps obvious and sequential? (e.g. install pkg → restart service → verify)
  │     → SKIP plan, just execute
  │
  ├─ 2-5 steps, low risk, files < 5?
  │     → SKIP plan, use todo.md instead (see todo-management skill)
  │
  └─ Multiple components / non-trivial design / risk of rework?
        → CREATE plan.md
```

### Plan Trigger Conditions

Create `plan.md` when ANY of:

- **Scope**: >5 files to create/modify across >2 directories
- **Risk**: Changes affect core infrastructure, data integrity, security, or production
- **Dependencies**: Step ordering matters, wrong order = rework
- **Design**: Requires non-trivial decisions (architecture, data model, API design)
- **Unfamiliar**: You don't fully understand the domain or codebase yet
- **Collaboration**: Multiple subagents or sessions needed
- **Rollback**: If something goes wrong, easy to undo? If no → plan

### Plan Skip Conditions

Do NOT create `plan.md` when ALL of:

- Single or few-file change
- Steps are linear and obvious
- Low risk (easy to undo)
- No design decisions needed
- You have full context

## Plan Format (when needed)

Keep it lightweight. No over-engineering.

```markdown
# Plan: [Task Name]

## Goal
One sentence.

## Steps
- [ ] 1. Step one
- [ ] 2. Step two
  - [ ] 2.1 Sub-step
- [ ] 3. Step three

## Files
- Modify: path/to/file
- Create: path/to/new/file

## Rollback
How to undo if it goes wrong.
```

**Rules:**
- No header boilerplate
- No architecture sections for simple tasks
- Keep steps at a level where each `[ ]` = one focused action
- Delete `plan.md` when done (not commit it — it's a scratch file)
- If a PROGRESS.md already exists, update that instead of creating plan.md

## Integration

- For complex tasks → invoke `writing-plans` skill for full implementation plans
- For medium tasks → just create a lightweight `plan.md` using the format above
- For simple tasks → bypass planning entirely

## Examples

**Needs plan.md ❌:**
- "Refactor the auth module from JWT to session-based" (risk + design + dependencies)
- "Add a new AI model provider integration" (unfamiliar + multiple files + design)
- "Rewrite the data pipeline for 10x throughput" (risk + scope + dependencies)

**Doesn't need plan.md ✅:**
- "Fix typo in README" (one file, trivial)
- "Add --verbose flag to CLI" (one file, linear)
- "Update dependency version" (one command, obvious)
- "Rename a function" (editor refactor, trivial)
