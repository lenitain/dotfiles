---
name: privilege-escalation
description: Use when executing commands that require elevated privileges (package management, system services, file permissions, system configuration)
---

# Privilege Escalation

## The #1 Rule: One Attempt, Then Stop

This skill exists to escalate privileges exactly **once** per operation — and to **stop** the moment that attempt fails.

Repeated attempts are not a recovery strategy; they are the failure mode. Every failed authentication (a cancelled prompt, a mistyped password, a timed-out dialog) consumes the system's retry budget (`faillock` / `pam_tally2` account lockouts, polkit deny policies) and can **lock the user's account or freeze the session entirely**. A cancelled prompt is the user declining — retrying until lockout is the worst possible outcome, and preventing it is this skill's primary job.

**One attempt. Any failure ends the attempt. Stop. Never retry, never loop, never switch tools to "try again".**

## Standard Flow

1. **Before escalating, ask yourself**: can this be done without root, or by the user themselves? If so, say so instead of escalating. Privilege escalation is the escape window, not the default path.
2. **Check polkit is available**: `which pkexec`
   - Available → go to step 3.
   - Unavailable → **stop here. Do not fall back to sudo.** Pick one: ask the user how to proceed, or terminate the operation with a clear message (see below).
3. **Run the privileged command with `pkexec` once.**
4. **Evaluate the single result:**
   - Success → continue.
   - Cancel / wrong password / auth failure / timeout / any refusal → **STOP immediately.** Report what was needed and why it could not be done. Do not retry.

## What Counts as a Terminal Failure

Any of these ends the operation:

- User clicks **Cancel** on the polkit dialog
- Password prompt times out
- Wrong password
- `pkexec` exits non-zero with an authentication error
- No polkit agent is available and no terminal prompt appears
- `pkexec` is not installed

In every case: **report and stop.**

## Password Handling

- `pkexec` shows a graphical prompt when a polkit authentication agent is running (typical on desktop sessions).
- Without a graphical agent, `pkexec` prompts on the terminal; if neither exists it fails immediately — treat that as terminal.
- **Never** embed a password in a command line, script, or environment variable. **Never** use `expect`-style automation to feed passwords. If a password is needed, the user types it into the prompt themselves — or you stop and ask the user.

## If pkexec Is Unavailable

Do **not** silently switch to sudo: sudo carries the same retry-lockout risk and bypasses polkit policy. Instead choose one of:

- **Ask the user**: "pkexec is unavailable and this command needs root. How should I proceed? (e.g. run it yourself, install/enable a polkit agent, or provide credentials)"
- **Terminate**: abort the operation and explain what was blocked and why.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Retrying `pkexec` after a cancelled prompt | Treat cancel as a terminal "no" — stop |
| Looping a retry loop around the prompt | One attempt per operation, ever |
| Falling back to sudo when pkexec fails | Stop and ask the user, or abort |
| Embedding the password in a command | Never handle passwords yourself; the user types them |
| Ignoring the exit code and "trying again" | A non-zero auth exit ends the operation |

## Red Flags - STOP

If you catch yourself thinking:

- "Maybe the prompt timed out, I'll try again"
- "One more attempt won't hurt"
- "sudo worked last time, I'll just use sudo"
- "The user probably wants this, retry until it works"

**Stop. The single attempt is done. Report and stop.**

## Integration with AGENTS.md

This skill implements the rule from AGENTS.md:
> "Never run `rm -rf /` or equivalent destructive commands without explicit confirmation. Prefer `git stash` over `git checkout --` when reverting changes. Before force-pushing, always confirm with the user."

Privilege escalation is a safety-sensitive operation. The "one attempt, then stop" rule protects the user's account and session from lockout — the same way confirming destructive commands protects their data.
