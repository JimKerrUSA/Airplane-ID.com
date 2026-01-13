# Setting Up GitHub to sync with Gitea (git.kerrnet.net)
To use this template to sync to git.kerrnet.net the following steps must be followed.

1. set up a repo in git.kerrnet.net with the exact same name that will be used on GitHub.
    - An org can be used for this repo as long as user jkerr can get to it.  

2. Create the Repo on GitHub with the exact same name. 
    - Use this template to create the repo.  It establishes the core strcture needed for Claude Code.

3. After establishing the GitHub proejct, the following variables need to be configured:
    - Go into the new Repo that was created (e.g. gitea-sync)
    - Click Settings 
    - Left bar select Secrets and Variables
    - Select Actions

    - Click New Repository Secret (green button)
    - Create the following variables 

        - GITEA_USER              jkerr
        - GITEA_TOKEN             
        - GITEA_URL               git.kerrnet.net

    - NOTE: If using an org (eg.LJAero) in git.kerrnet.net add this variable:
        - GITEA_ORG               LJAero
        - ** If Org is not set it will default to GITEA_USER repo.


# Project Name

Brief description of what this project does.

## Overview

[More detailed explanation of the project's purpose and goals]

## Getting Started

### Prerequisites

- [List requirements]

### Installation

```bash
# Installation steps
```

### Usage

```bash
# How to run/use the project
```

## Project Structure

```
project/
├── README.md      # This file
├── CLAUDE.md      # Instructions for Claude AI
├── CONTEXT.md     # Session continuity for AI-assisted development
└── ...
```

## Development

This project uses Claude AI for development assistance. The `CONTEXT.md` file maintains state between sessions.

### Working with Claude

1. Start each session by having Claude read `CONTEXT.md`
2. Claude will update `CONTEXT.md` as work progresses
3. End sessions by ensuring `CONTEXT.md` reflects current state

## License

[Your license here]
