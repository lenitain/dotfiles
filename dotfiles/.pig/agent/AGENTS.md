# AGENTS.md

## Rules

- Keep changes scoped; do not create issues or pull requests, or post comments.

## Skills

- Before executing a non-trivial task, scan the available skills for one that matches the work; if found, load it (read its SKILL.md) and follow it. Skills encode established practice - check them before writing new code. If none applies or the task is trivial, proceed directly.

## Planning

- A `planning-tasks` skill offers a mindset for breaking work into a visible checked-box checklist. Let the task's real scope decide: when it might benefit from structure, offer a checklist; when it's simple enough to just do, skip it. Remember the option exists - do not prescribe when to use it.

## Style

- Follow nearby code and use idiomatic code in the project's languages.
- Name variables, modules, methods, and other symbols simply, elegantly, and expressively. Be creative while keeping names clear, consistent with established terminology, and idiomatic.
- When passing arguments, use the parameter's conversion traits directly (such as `Into<_>` or `AsRef<_>`); avoid eager conversions like `.to_string()`, `.to_owned()`, and `.as_ref()` unless ownership, type inference, or semantics require them.
- Comment only behavior the code cannot explain.

## Code Changes

- Search and reuse first. For new features, extend existing infrastructure or data structures with general, reusable capabilities when that keeps the final code concise.
- For refactors, inspect the whole target module and its callers first. Look for duplicated work, redundant I/O, underpowered return values, one-use wrappers, and reusable cross-platform abstractions; implement high-confidence, behavior-preserving simplifications while preserving error, fallback, and platform semantics.
- Keep diffs minimal and avoid unrelated refactors. Prefer clear, flat control flow and positive predicates; use standard combinators, early returns, ordered branches, and match guards to express cases directly and avoid nested conditionals or compound negation.
- Keep responsibility boundaries clear and cohesive. Prefer pure functions and explicit invariants; favor convention over configuration when invariants can eliminate state or coordination. Put reusable code in the lowest suitable shared layer; avoid unnecessary dependencies and allocations. Prefer borrowed values and existing wrappers.
- Keep async I/O non-blocking, preserve platform behavior, and follow existing error boundaries.
- For renames or refactors, update all related variables, functions, parameters, modules, methods, types, derived types, exports, tests, configuration keys, documentation, and bindings.
- Do not add or modify tests unless requested.

## Workarounds

- Fix the code instead of masking the failure. Do not stub out functions, leave placeholder implementations such as `todo!()`, suppress errors with broad allowances, or delete functionality to make compilation, lints, or checks pass.
- If you need a paragraph-long comment to justify why the workaround is OK, the code is wrong — fix the code.

## Validation

- Prefer targeted checks for affected parts before whole-suite checks.
- Prefer fast check commands over full builds unless artifacts are needed. Do not use `--release` unless requested.
- When investigating bugs, add temporary diagnostics when useful, reproduce, and inspect the logs to pinpoint the cause; remove diagnostics before handoff.
- Run relevant existing tests when needed, then inspect `git diff` and verify that only intended files changed.

## Safety

- Never commit secrets, API keys, or credentials.
- **MANDATORY: Before executing ANY command that requires elevated privileges, you MUST load and follow the `privilege-escalation` skill.** This includes package management, system services, file permissions, and system configuration.
- When privileged access is required, use polkit (e.g. `pkexec`) instead of `sudo` or prompting for a password.
- Never run `rm -rf /` or equivalent destructive commands without explicit confirmation.
- Prefer `git stash` over `git checkout --` when reverting changes.
- Before force-pushing, always confirm with the user.

---

## Response

- At the end of each response, include a brief recap summarizing key actions taken and outcomes.
- Recap must be self-contained: write it so a reader who sees only the recap (without the conversation above) understands what was done and why. Include the subject, the action, and the result — not just a dangling conclusion.
- **Recap must use blockquote format** (using markdown `> text` syntax) to give it a visually distinct, bordered appearance with the left vertical bar.
