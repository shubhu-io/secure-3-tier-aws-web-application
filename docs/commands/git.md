# Git

Reference commands for Git version control. This project uses GitHub for source control with GitHub Actions CI/CD.

## Installation

```bash
# macOS
brew install git

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y git

# Windows: Download from git-scm.com or use Chocolatey
choco install git

# Verify
git --version
```

## Version Check

```bash
git --version
```

## Repository Setup

```bash
# Initialize a new Git repository
git init

# Clone an existing repository (this project)
git clone https://github.com/shubhu-io/secure-ntier-cloud-platform.git

# Clone with SSH
git clone git@github.com:shubhu-io/secure-ntier-cloud-platform.git

# Clone a specific branch
git clone -b develop https://github.com/shubhu-io/secure-ntier-cloud-platform.git
```

## Status & Information

```bash
# Check current state
git status

# View commit history
git log              # Default: recent commits
git log --oneline    # One-line per commit
git log --graph      # ASCII art history
git log --all --oneline --graph --decorate

# Show current branch
git branch

# Show current working directory info
git status --short   # Compact status

# Show differences from last commit
git diff

# Show staged changes
git diff --staged

# Show remote URLs
git remote -v
```

## Branching & Merging

```bash
# List branches
git branch

# Create a new branch
git branch <branch-name>

# Create and switch to new branch
git checkout -b <branch-name>

# Switch to existing branch
git checkout <branch-name>

# Modern alternative (Git 2.23+)
git switch <branch-name>

# Rename current branch
git branch -m <new-name>

# Delete branch (local)
git branch -d <branch-name>

# Delete branch (force, if not merged)
git branch -D <branch-name>

# Merge branch into current
git merge <branch-name>

# Rebase onto another branch
git rebase <branch-name>

# Abort rebase
git rebase --abort

# Cherry-pick a commit
git cherry-pick <commit-hash>
```

## Staging & Saving

```bash
# Stage file(s)
git add <file>

# Stage all changes
git add .

# Stage everything including deleted files
git add -A

# Restage file (after edit)
git add <file>

# Unstage file
git reset <file>

# Reset entire staging area
git reset

# Commit staged changes
git commit -m "descriptive commit message"

# Commit with extended description
git commit -m "subject" -m "body"

# Amend last commit (edit message or add files)
git commit --amend

# Amend without editing message
git commit --amend --no-edit

# Reset to a previous commit (soft - keeps changes)
git reset --soft <commit-hash>

# Reset to a previous commit (mixed - unstages changes)
git reset --mixed <commit-hash>  # Default, also --mixed

# Reset to a previous commit (hard - discards changes)
git reset --hard <commit-hash>

# Recover lost commits (reflog)
git reflog
git checkout <ref>   # Recover lost commit
```

## Inspection

```bash
# Show commit details
git show <commit-hash>

# Show diff of commit
git show <commit-hash> --stat

# Show who changed what and when
git blame <file>

# View tags
git tag

# Show remote tracking branches
git remote

# Fetch from remote without merging
git fetch

# Pull (fetch + merge)
git pull

# Push to remote
git push

# Push current branch
git push origin <branch-name>

# Force push (use with caution!)
git push --force

# Force push with lease (safer)
git push --force-with-lease
```

## Ignoring Files

```bash
# Create/update .gitignore
# This project uses .gitignore to exclude:
# - node_modules/
# - dist/
# - *.tfstate
# - .env files
# - .git/
# - *.lock files

# Add file to ignore (global)
git global-ignores

# Or edit .gitignore manually and:
git add .gitignore
git commit -m "Update gitignore"
```