---
description: Audit changelog entries before release
---
Audit changelog entries for all commits since the last release.

## Process

1. **Find the last release tag:**
   ```bash
   git tag --sort=-version:refname | head -1
   ```

2. **List all commits since that tag:**
   ```bash
   git log <tag>..HEAD --oneline
   ```

3. **Discover all CHANGELOG.md files in the repo:**
   ```bash
   find . -name CHANGELOG.md -not -path './node_modules/*'
   ```

4. **Read each discovered CHANGELOG.md's [Unreleased] section.**

5. **For each commit, check:**
   - Skip: changelog updates, doc-only changes, release housekeeping
   - Skip: changes to generated files (e.g. model catalogs, lock files) unless accompanied by an intentional product-facing change in non-generated source/docs.
   - Determine which package(s) the commit affects (use `git show <hash> --stat`)
   - Match affected directories to the closest CHANGELOG.md
   - Verify a changelog entry exists in the matched CHANGELOG.md
   - For external contributions (PRs), verify format: `Description ([#N](url) by [@user](url))`

6. **Detect shared/internal packages:**
   If a commit affects a package that is a dependency of another package in the same repo (monorepo layout), and the change is user-facing, the entry should also be duplicated to the user-facing package's changelog. Determine the user-facing package by:
   - Looking for a `CHANGELOG.md` in a package that other packages reference as a dependency
   - Or the package whose README/docs suggest it's the primary user-facing entry point

7. **Add New Features section:**
   - Insert a `### New Features` section at the start of `## [Unreleased]` in the primary user-facing package's CHANGELOG.md.
   - Propose the top new features to the user for confirmation before writing them.
   - Link to relevant docs and sections whenever possible.

8. **Report:**
   - List commits with missing entries
   - List entries that need cross-package duplication
   - Add any missing entries directly

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
