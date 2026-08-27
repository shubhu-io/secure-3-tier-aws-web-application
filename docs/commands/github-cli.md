# GitHub CLI (gh)

Reference commands for GitHub Command Line Tool. This project uses GitHub Actions for CI/CD.

## Installation

```bash
# macOS
brew install gh

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y gh

# Windows: Download from github.com/cli/releases

# Or using SDKMAN (optional)
sdk install gh

# Verify
gh --version

# Authentication
gh auth login   # Follow interactive prompt
gh auth status   # Check authentication status
gh auth refresh  # Refresh token
```

## Version Check

```bash
gh --version
```

## Repository Operations

```bash
# Clone a repository
gh repo clone shubhu-io/secure-ntier-cloud-platform

# Clone with specific branch
gh repo clone shubhu-io/secure-ntier-cloud-platform --branch develop

# Create a new repository
gh repo create secure-ntier-cloud-platform --public
gh repo create secure-ntier-cloud-platform --private

# View repository information
gh repo view
gh repo view --json name,description,url,private

# Fork a repository
gh repo fork shubhu-io/secure-ntier-cloud-platform

# Delete a repository (use with caution!)
gh repo delete secure-ntier-cloud-platform --yes
```

## Pull Request Operations

```bash
# Create a pull request
gh pr create        # Interactive prompt

# Create PR from command line
gh pr create --title "feat: add new feature" \
             --body "Description of changes" \
             --base develop \
             --head feature/my-feature

# List pull requests
gh pr list

# List PRs assigned to you
gh pr list --author @me

# View PR details
gh pr view          # Current PR
gh pr view <pr-number>  # Specific PR

# Check out a PR branch locally
gh pr checkout <pr-number>

# Add reviewers
gh pr review add <username>

# Request review
gh pr review request <username>

# Merge a pull request
gh pr merge <pr-number>    # Merge with default method (merge)
gh pr merge <pr-number> --auto   # Auto-merge if possible
gh pr merge <pr-number> --squash # Squash merge
gh pr merge <pr-number> --rebase # Rebase merge

# List mergable PRs
gh pr search --is-mergeable true

# List your open PRs
gh pr list --author @me --state open
```

## Issue Operations

```bash
# Create an issue
gh issue create --title "Bug report" --body "Description"

# List issues
gh issue list

# List issues assigned to you
gh issue list --assignee @me

# View issue
gh issue view           # Current issue
gh issue view <issue-number>  # Specific issue

# Close issue from command line
gh issue close <issue-number>

# Reopen issue
gh issue reopen <issue-number>
```

## Workflow Operations

```bash
# List GitHub Actions workflows
gh workflow list

# View workflow run
gh workflow run <workflow-file>  # Trigger workflow
gh run list                     # List recent runs
gh run view <run-id>             # View specific run
gh run cancel <run-id>           # Cancel running run
gh run rerun <run-id>            # Rerun failed workflow

# Check workflow syntax
gh workflow syntax .             # Validate workflow files

# List workflow runs for a branch
gh run list --branch develop
```

## Repository Discovery

```bash
# Search repositories
gh repo search "secure-ntier"

# Search issues
gh issue search "bug"

# Search code
gh code search "TODO"

# List your repositories
gh repo list

# Your repositories
gh repo list --owner @me
```