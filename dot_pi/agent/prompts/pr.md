---
description: Review PRs from URLs with structured issue and code analysis
argument-hint: "<PR-URL>"
---
You are given one or more GitHub PR URLs: $@

For each PR URL, do the following in order:
1. Add the `inprogress` label to the PR via GitHub CLI before analysis starts. If adding the label fails, report that explicitly and continue.
2. Read the PR page in full. Include description, all comments, all commits, and all changed files.
3. Identify any linked issues referenced in the PR body, comments, commit messages, or cross links. Read each issue in full, including all comments.
4. Analyze the PR diff. Read all relevant code files in full with no truncation from the current main branch and compare against the diff. Do not fetch PR file blobs unless a file is missing on main or the diff context is insufficient. Include related code paths that are not in the diff but are required to validate behavior.
5. Check for a changelog entry. Discover relevant CHANGELOG.md files by matching changed file paths to the nearest CHANGELOG.md (e.g. `find . -name CHANGELOG.md -not -path './node_modules/*'`). Report whether an entry exists. If missing, state that a changelog entry is required before merge and that you will add it if the user decides to merge. Use the changelog format reference below. Verify:
   - Entry uses correct section (`### Breaking Changes`, `### Added`, `### Fixed`, etc.)
   - External contributions include PR link and author: `Fixed foo ([#123](https://github.com/owner/repo/pull/123) by [@user](https://github.com/user))`
   - Breaking changes are in `### Breaking Changes`, not just `### Fixed`
6. Check if documentation files (README.md, docs/*.md, examples/**/*.md) near the changed packages require modification. Discover these files dynamically based on the directory structure of changed packages. This is usually the case when existing features have been changed, or new features have been added.
7. Provide a structured review with these sections:
   - Good: solid choices or improvements
   - Bad: concrete issues, regressions, missing tests, or risks
   - Ugly: subtle or high impact problems
8. Add Questions or Assumptions if anything is unclear.
9. Add Change summary and Tests.

Output format per PR:
PR: <url>
Changelog:
- ...
Good:
- ...
Bad:
- ...
Ugly:
- ...
Questions or Assumptions:
- ...
Change summary:
- ...
Tests:
- ...

If no issues are found, say so under Bad and Ugly.

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
