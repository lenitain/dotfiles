---
name: planning-tasks
description: "A mindset tool for organizing work into a visible checked-box checklist. Use when a task might benefit from structure - multi-step, touches several files or modules, needs verification, or is exploratory. It is an option, not a mandate: whether a task actually warrants a checklist is a judgment you make from the task itself. Simple one-step work can skip it."
---

# Planning Tasks

## Overview

A checklist is a tool for staying organized on work that has real structure - several steps, several files, or a result that needs verifying. This skill is a nudge to consider it, not a command. Use it when you judge it helps; skip it when a task is simple enough to just do.

## When to consider it

A checklist helps when a task:

- Needs several steps or touches several files, modules, or subsystems
- Needs verification (build, tests, run, inspect output)
- Is exploratory (investigate, trace, review, compare, survey)
- Has multiple valid approaches, or may change direction mid-way
- Is long enough that progress needs tracking

It is usually overkill when:

- One command or quick lookup
- A direct answer with no change or investigation
- A one-line, context-free edit
- The user says "just do it" or "no plan needed"

The task's real scope decides - not a hard rule. If it's borderline, offer a short 3-5 box checklist; that's cheaper than an abandoned big task.

## The Pattern

### 1. Decompose before executing

On receiving a task that warrants planning, stop and break it into steps. Each step must be:

- **Complete on its own** - no need to see the rest
- **Verifiable** - has a clear "done" standard
- **Right-sized** - roughly one file change, one module, one test run, one refactor. Not "refactor the whole module", not "change one variable".

### 2. Show a TODO list

At the top of your reply, print the checklist as markdown boxes. Do not wait for confirmation - list it, then start executing the first step immediately:

```
I'll work through this as:
- [ ] Step 1 ...
- [ ] Step 2 ...
- [ ] Step 3 ...
```

### 3. Execute and check off, one at a time

After finishing each step:

- Change that line from `- [ ]` to `- [x]`
- Say in one or two sentences what you did and the result
- If reality diverges, update the list (add, merge, or remove items) before continuing

Keep the list visible in each reply so the user always sees progress.

### 4. Stop only at consequential forks

Pause and ask only when:

- There are multiple reasonable approaches that change the direction (architecture, implementation choice)
- You need info, preference, or confirmation from the user
- The task's premise turns out wrong and you need to change course
- Proceeding would delete/overwrite user work or affect other modules

Otherwise keep going. Do not pause just to pause - that wastes the user's time.

### 5. Summarize on completion

When the last item is done, give a short wrap-up:

- What you did
- Files changed (list them)
- How to verify (command or test)
- Anything outstanding or worth noting

## Common Mistakes

- Plunging in and losing track of the whole task
- Steps too coarse ("refactor the module") or too fine ("change a variable")
- Pausing for confirmation on every step
- Letting the checklist drift from what actually happened
- Finishing without summarizing what changed

## Integration with AGENTS.md

This skill reflects the note in AGENTS.md:

> "Let the task's real scope decide: when a task might benefit from structure, offer a checklist; when it's simple enough to just do, skip it."

Planning is a resource, not a rule - it reduces wasted effort and keeps the user informed of progress.
