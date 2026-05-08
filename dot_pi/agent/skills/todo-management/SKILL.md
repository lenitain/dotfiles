---
name: todo-management
description: Before multi-step work, decide if a todo.md helps track progress. Creates lightweight todo.md for medium-complexity tasks that don't need a full plan.
---

# Todo Management

Track progress with a lightweight `todo.md` for tasks that have clear, linear steps but are too simple for a full plan.

## Decision: todo.md vs plan.md vs nothing

```
Task arrives
  │
  ├─ Trivial (1 step, < 1 min)?
  │     → Nothing needed, just do it
  │
  ├─ Medium (2-5 clear steps, low risk, obvious order)?
  │     → CREATE todo.md (this skill)
  │
  └─ Complex (design decisions, risk, >5 files, dependencies)?
        → CREATE plan.md (see plan-on-demand skill)
```

### todo.md Triggers

Create `todo.md` when ALL of:

- 2-5 steps that are clear and sequential
- Low risk (easy to undo mistakes)
- You have full context (no unfamiliar code/domain)
- No significant design decisions needed
- Steps are independent enough to parallelize or skip around

### todo.md Skip Conditions

Do NOT create `todo.md` when:

- Single step — just do it
- Steps are already in your working memory (finishing in <2 min)
- A PROGRESS.md or plan.md already tracks this work
- You're in the middle of active execution (context is fresh)

## File Format

```markdown
# Todo: [Task Name]

- [ ] Step 1: description
- [ ] Step 2: description
- [ ] Step 3: description
```

**Format rules:**
- Title is `# Todo: <brief name>`
- Each step is `- [ ] Action: description`
- No sub-tasks unless truly needed (keep flat)
- No priority labels, no deadlines, no estimate
- Minimal — just enough to track what's left

## Todo Lifecycle

1. **Create** — at root of working directory (or project root)
2. **Update** — check off `[x]` as each step finishes
3. **Delete** — when `- [ ]` count hits 0, remove the file
4. **Never commit** — `todo.md` is a scratch file, add to .gitignore if needed

## During Execution

- After each step, update `todo.md` with `[x]`
- If new steps emerge during work, append them
- If scope grows beyond 5 steps, consider upgrading to `plan.md` (see plan-on-demand)

## Integration with Other Skills

- **Subagent-driven development**: Pass `todo.md` content to implementer subagents as progress context
- **Verification-before-completion**: Check `todo.md` to confirm all steps are `[x]` before claiming done
- **plan-on-demand**: Use together — if task crosses complexity threshold mid-work, upgrade to plan.md

## Examples

**Good for todo.md ✅:**
- "Update 3 config files for new database connection"
- "Add input validation to 2 endpoints"
- "Install and configure Redis locally"
- "Write unit tests for utils module"

**Too simple for todo.md ❌:**
- "Fix a typo" (1 step)
- "Run npm install" (1 step)
- "Restart the server" (1 step)

**Needs plan.md instead ❌:**
- "Implement OAuth2 flow with 3 providers" (design + risk + dependencies)
- "Migrate database from SQLite to PostgreSQL" (risk + scope + rollback)
