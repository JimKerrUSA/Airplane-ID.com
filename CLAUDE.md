# Project Instructions for Claude

## Developer
- Name: Jim Kerr
- Email: jim@kerr.aero

## Development Environment Overview

This project operates in a **dual-repository system**:

| Environment | Repository | How Changes Sync |
|-------------|------------|------------------|
| **Claude Code (Terminal)** | git.kerrnet.net (Gitea) | Direct push via `gsave` |
| **Claude.ai (Web)** | github.com | GitHub Action syncs to Gitea on merge |

### How It Works

```
┌─────────────────┐         ┌─────────────────┐
│  Claude.ai      │         │  Claude Code    │
│  (Web IDE)      │         │  (Terminal)     │
└────────┬────────┘         └────────┬────────┘
         │                           │
         ▼                           ▼
┌─────────────────┐         ┌─────────────────┐
│  GitHub.com     │────────▶│ git.kerrnet.net │
│                 │  sync   │    (Gitea)      │
└─────────────────┘         └─────────────────┘
                                    │
                            Source of Truth
```

- **Gitea (git.kerrnet.net)** is the source of truth
- **GitHub** is used for Claude.ai web development and cloud features
- A GitHub Action automatically syncs merged PRs from GitHub → Gitea
- Local terminal work pushes directly to Gitea

### If You're Claude Code (Terminal)
- You have access to git helper commands: `gsave`, `gpush`, `gpull`, `gstatus`, etc.
- Always use HTTPS for git.kerrnet.net (SSH is unreliable behind HAProxy)
- Push directly to Gitea with `gsave "commit message"`

### If You're Claude.ai (Web)
- Changes commit to GitHub
- Create PRs for review
- On merge, GitHub Action syncs to Gitea automatically
- You do NOT have access to the terminal git commands

## CRITICAL: CONTEXT.md Maintenance

Every project has a CONTEXT.md file for session continuity. You MUST:

1. **Read CONTEXT.md at the start** of every session to understand current state
2. **Update CONTEXT.md** as you work:
   - Add decisions made to "Recent Decisions"
   - Update "Current State" when things change
   - Update "Next Steps" with upcoming work
   - Add dated entries to "Session Log" for significant progress
3. **Before ending a session**, ensure CONTEXT.md reflects where we left off

This allows Jim to switch between computers, environments, and sessions seamlessly.

Example session log entry:
```
### 2026-01-10
- Implemented user authentication
- Fixed bug in login form
- Next: Add password reset flow
```

## Code Preferences
- Always use best practices
- Keep code clean and well-documented
- Prefer simple, maintainable solutions
- Use modern JavaScript/TypeScript patterns
- For iOS: use SwiftUI when possible
- Commit messages should be clear and descriptive

## Terminal Git Commands (Claude Code only)

These commands are available when working in the terminal:

| Command | Description |
|---------|-------------|
| `gsave "msg"` | Add, commit, and push (quick save) |
| `gstatus` | Show git status |
| `gpull` | Pull from origin |
| `gpush` | Push to origin |
| `gcommit "msg"` | Add all files and commit |
| `glog` | Show recent commits |
| `gbranch [name]` | List branches or create new |
| `gswitch <name>` | Switch to branch |
| `gmerge <name>` | Merge branch into current |
| `gdiff` | Show uncommitted changes |
| `gundo` | Undo last commit (keep changes) |

## Project-Specific Instructions
<!-- Add project-specific instructions below this line -->

