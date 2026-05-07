---
agent: git.pr
---

# Create GitHub Pull Request

Create a GitHub Pull Request for the current feature branch using the GitHub CLI.

## When to Use

- After completing `/implement` and all changes are committed
- When ready to submit feature for review
- To create draft PRs for work-in-progress features

## Prerequisites

- GitHub CLI (`gh`) installed and authenticated
- On a feature branch (not main/master)
- Changes committed (or will be prompted to commit)
- Feature specification exists in docs/

## Usage

```bash
# Standard PR creation
/git.pr

# Create draft PR
/git.pr --draft

# PR with labels
/git.pr --label enhancement,performance

# Request specific reviewers
/git.pr --reviewer alice,bob --label needs-review

# Custom target branch
/git.pr --base develop
```

## What It Does

1. ✅ Validates branch and feature directory
2. ✅ Loads spec.md for PR title and description
3. ✅ Checks for uncommitted changes (prompts to commit)
4. ✅ Pushes branch to origin
5. ✅ Creates PR with auto-generated title/body
6. ✅ Outputs PR URL and next steps

## PR Structure

**Title**: `[Feature NNN] <Feature Name>`  
**Body**: Includes overview, changes, related issues, and artifact links

## Manual Alternative

If GitHub CLI is unavailable:
```bash
git push -u origin <branch>
gh pr create --web  # Opens browser
```

## See Also

- `/git.feature` - Create feature branch
- `/git.commit` - Commit changes
- `/git.validate` - Validate branch naming
