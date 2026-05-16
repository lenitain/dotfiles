---
description: Finish the current task end-to-end with changelog, commit, and push
argument-hint: "[instructions]"
---
Wrap it.

Additional instructions: $ARGUMENTS

Determine context from the conversation history first.

Rules for context detection:
- If the conversation already mentions a GitHub issue or PR, use that existing context.
- If the work came from `/is` or `/pr`, assume the issue or PR context is already known from the conversation and from the analysis work already done.
- If there is no GitHub issue or PR in the conversation history, treat this as non-GitHub work.

Unless I explicitly override something in this request, do the following in order:

1. Add or update the relevant changelog entry under `## [Unreleased]`. Discover the correct CHANGELOG.md by matching changed files to the nearest CHANGELOG.md in the repo. Use the format reference below.
2. If this task is tied to a GitHub issue or PR and a final issue or PR comment has not already been posted in this session, draft it in my tone, preview it, and post exactly one final comment.
3. Commit only files you changed in this session.
4. If this task is tied to exactly one GitHub issue, include `closes #<issue>` in the commit message. If it is tied to multiple issues, stop and ask which one to use. If it is not tied to any issue, do not include `closes #` or `fixes #` in the commit message.
5. Detect the default branch: `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null \| sed 's@.*/@@'` or fall back to `main`. If the current branch is not the default branch, stop and ask what to do. Do not push from another branch unless I explicitly say so.
6. Push the current branch.

Constraints:
- Never stage unrelated files.
- Never use `git add .` or `git add -A`.
- Run required checks before committing if code changed.
- Do not open a PR unless I explicitly ask.
- If this is not GitHub issue or PR work, do not post a GitHub comment.
- If a final issue or PR comment was already posted in this session, do not post another one unless I explicitly ask.

## Changelog Format Reference

Sections (in order):
- `### Breaking Changes` - API changes requiring migration
- `### Added` - New features
- `### Changed` - Changes to existing functionality
- `### Fixed` - Bug fixes
- `### Removed` - Removed features

Attribution:
- Internal: `Fixed foo ([#123](https://github.com/owner/repo/issues/123))`
- External: `Added bar ([#456](https://github.com/owner/repo/pull/456) by [@user](https://github.com/user))`
