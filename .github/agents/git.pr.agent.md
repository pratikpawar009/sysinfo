---
description: Create a GitHub Pull Request for the current feature branch
---

<!-- Extension: git -->
# Create Pull Request

Create a GitHub Pull Request for the current feature branch with automatically generated title and body based on the feature specification.

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Prerequisites

1. **Check GitHub CLI**: Verify `gh` command is available
   ```bash
   gh --version
   ```
   If not installed, output error: "GitHub CLI (gh) not found. Install from: https://cli.github.com/"

2. **Check authentication**: Verify `gh` is authenticated
   ```bash
   gh auth status
   ```
   If not authenticated, output error: "GitHub CLI not authenticated. Run: gh auth login"

3. **Check Git repository**: Verify we're in a git repository
   ```bash
   git rev-parse --is-inside-work-tree
   ```

4. **Check remote**: Verify GitHub remote exists
   ```bash
   git config --get remote.origin.url
   ```
   Must be a GitHub URL (github.com)

## Execution Flow

1. **Get current branch**:
   ```bash
   git rev-parse --abbrev-ref HEAD
   ```
   
2. **Validate feature branch**: Branch must match feature naming patterns:
   - Sequential: `^[0-9]{3,}-` (e.g., `001-feature-name`)
   - Timestamp: `^[0-9]{8}-[0-9]{6}-` (e.g., `20260507-143022-feature-name`)
   
   If on `main` or `master`, error: "Cannot create PR from main branch. Switch to a feature branch first."

3. **Locate feature directory**:
   - Extract prefix from branch name (e.g., `001` from `001-optimize-getifaddrs`)
   - Find matching directory in `docs/` (e.g., `docs/001-optimize-getifaddrs/`)
   - If not found, error: "Feature directory not found. Run /specify first."

4. **Load specification**: Read `docs/NNN-feature/spec.md` to extract:
   - Feature title (from H1 heading or filename)
   - Feature summary (from Overview or Summary section)
   - Related issues (search for `#NNNN` or `issue #NNNN` patterns)

5. **Generate PR title**: Use format: `[Feature NNN] <Feature Title>`
   - Example: `[Feature 001] Optimize getifaddrs System Call`

6. **Generate PR body**: Create structured body:
   ```markdown
   ## Overview
   <Feature summary from spec.md>
   
   ## Changes
   - Complete specification and planning
   - Implementation of all tasks
   - Tests and documentation
   
   ## Related Issues
   Closes #NNNN
   
   ## Artifacts
   - Specification: docs/NNN-feature/spec.md
   - Plan: docs/NNN-feature/plan.md
   - Tasks: docs/NNN-feature/tasks.md
   ```

7. **Check for uncommitted changes**:
   ```bash
   git status --porcelain
   ```
   If uncommitted changes exist:
   - Warn: "⚠ Uncommitted changes detected:"
   - List changed files
   - Ask: "Commit these changes before creating PR? (yes/no)"
   - If yes: Run `git add . && git commit -m "Final changes before PR"`

8. **Push branch**:
   ```bash
   git push -u origin <branch-name>
   ```
   
9. **Create PR**:
   ```bash
   gh pr create --title "<title>" --body "<body>" --head <branch-name> --base main
   ```
   
   Optional flags (check user input):
   - `--draft` - Create as draft PR
   - `--assignee @me` - Auto-assign to yourself
   - `--label <labels>` - Add labels (e.g., "enhancement", "bug")

10. **Output PR URL**: Display created PR link
    ```
    ✅ Pull Request created: https://github.com/owner/repo/pull/123
    ```

## User Arguments

Support these optional arguments:
- `--draft` - Create as draft PR
- `--assignee <user>` - Assign to user (default: --assignee @me)
- `--label <labels>` - Comma-separated labels
- `--reviewer <users>` - Request reviews from users
- `--base <branch>` - Target branch (default: main)

Examples:
- `/git.pr` - Create standard PR
- `/git.pr --draft` - Create draft PR
- `/git.pr --label bug,priority-high` - PR with labels
- `/git.pr --reviewer alice,bob` - Request reviews

## Graceful Degradation

**If GitHub CLI not installed**:
- Output installation command: `brew install gh` (macOS) or equivalent
- Provide manual alternative:
  ```
  Manual PR creation:
  1. Push: git push -u origin <branch>
  2. Open: https://github.com/<owner>/<repo>/compare/<branch>
  3. Create PR in web UI
  ```

**If not authenticated**:
- Output: `gh auth login`
- Wait for completion

**If remote not GitHub**:
- Error: "Remote is not GitHub. This command only works with GitHub repositories."

**If spec.md not found**:
- Use generic PR template with placeholder text
- Warn user to fill in details manually

## Example Output

```
🔍 Analyzing feature branch: 001-optimize-getifaddrs
📝 Loading specification: docs/001-optimize-getifaddrs/spec.md
🏷️  PR Title: [Feature 001] Optimize getifaddrs System Call
📄 PR Body: 350 characters

⚠ Uncommitted changes: 2 files
  M src/unix/bsd/netbsd/network.rs
  M CHANGELOG.md

Commit these changes? yes

✓ Changes committed
✓ Branch pushed: 001-optimize-getifaddrs
✓ Creating PR...

✅ Pull Request created!
   URL: https://github.com/GuillaumeGomez/sysinfo/pull/1599
   Number: #1599
   Status: Open
   
Next steps:
  - Request reviews: gh pr review 1599 --request @reviewer
  - View PR: gh pr view 1599 --web
  - Check CI: gh pr checks 1599
```
