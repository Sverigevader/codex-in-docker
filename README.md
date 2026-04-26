# Codex Docker

Docker image setup for running Codex in a reproducible, but most importantly _isolated_ container environment.

## Overview

This repository is intended to hold the Dockerfile and supporting files needed to build a Codex development image.

The image installs:

- Codex CLI from the official Linux release binary
- Git and Git LFS
- Common shell tools such as `jq`, `curl`, `wget`, `ripgrep`, `fd`, `zip`, `unzip`, and `tar`
- Python 3 and build tools for typical project workflows

## Prerequisites

- Docker or Docker Desktop
- Git

## Build

From the repository root:

```sh
docker build -t codex -f src/Dockerfile .
```

## Run

```sh
docker run --rm -it codex
```

To mount the current project into the container and pass your API key:

```sh
docker run --rm -it \
  -e OPENAI_API_KEY \
  -v "$(pwd):/workspace" \
  -w /workspace \
  codex
```

On Windows PowerShell:

```powershell
docker run --rm -it `
  -e OPENAI_API_KEY `
  -v "${PWD}:/workspace" `
  -w /workspace `
  codex
```

You can also mount your local Codex configuration:

```sh
docker run --rm -it \
  -e OPENAI_API_KEY \
  -v "$HOME/.codex:/home/codex/.codex" \
  -v "$(pwd):/workspace" \
  -w /workspace \
  codex
```

## PowerShell Helper

Add this function to your PowerShell `$PROFILE` to start Codex in Docker from the folder you are currently in:

```powershell
function codex-docker {
    $workspace = (Get-Location).Path
    $codexHome = Join-Path $env:USERPROFILE ".codex"

    $dockerArgs = @(
        "run", "--rm", "-it",
        "-e", "OPENAI_API_KEY",
        "-v", "${workspace}:/workspace",
        "-w", "/workspace"
    )

    if (Test-Path $codexHome) {
        $dockerArgs += @("-v", "${codexHome}:/home/codex/.codex")
    }

    $dockerArgs += @("codex")
    $dockerArgs += $args

    docker @dockerArgs
}
```

Reload your profile:

```powershell
. $PROFILE
```

Then run Codex from any folder:

```powershell
codex-docker
```

You can also pass Codex CLI arguments through:

```powershell
codex-docker --version
codex-docker "explain this repo"
```

## Repository Layout

```text
.
├── src/
│   └── Dockerfile
├── README.md
├── .dockerignore
├── .editorconfig
├── .gitattributes
└── .gitignore
```

## Development Notes

- Keep generated files, local environment files, and editor-specific metadata out of version control.
- Prefer small, explicit Dockerfile changes so image behavior stays easy to review.
- Document any required environment variables or mounted paths in this README as they are added.

## License

Add a license before publishing or distributing this repository.
