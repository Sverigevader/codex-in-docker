# Codex Docker

Docker image setup for running Codex in a reproducible, but most importantly _isolated_ container environment.

## Overview

This repository is intended to hold the Dockerfile and supporting files needed to build a Codex development image.

The image installs:

- Codex CLI from the official Linux release binary
- Pi Coding Agent
- `pi-subagents` for Pi subagent delegation
- Git and Git LFS
- Common shell tools
- PowerShell Core (`pwsh`)
- Bubblewrap for Codex sandboxing support
- Python 3 and build tools for typical project workflows

## Prerequisites

- Docker or Docker Desktop
- Git

## Build

From the repository root:

```sh
docker build -t codex src
```

Or from inside the `src` folder:

```sh
docker build -t codex .
```

## Run

```sh
docker run --rm -it codex
```

If `OPENAI_API_KEY` is not set, the container starts Codex and prints a note that you need to authenticate interactively with the device-code login flow shown by the Codex CLI.

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

If you mount an existing Codex configuration, you can omit `-e OPENAI_API_KEY`:

```sh
docker run --rm -it \
  -v "$HOME/.codex:/home/codex/.codex" \
  -v "$(pwd):/workspace" \
  -w /workspace \
  codex
```

## PowerShell Helper

Add these functions to your PowerShell `$PROFILE` to start tools in Docker from the folder you are currently in:

```powershell
function Invoke-CodexDocker {
    param(
        [string[]]$Command = @("codex")
    )

    $workspace = (Get-Location).Path
    $codexVolume = "codex-home"
    $piVolume = "pi-home"

    $dockerArgs = @(
        "run", "--rm", "-it",
        "-e", "OPENAI_API_KEY",
        "-v", "${codexVolume}:/home/codex/.codex",
        "-v", "${piVolume}:/home/codex/.pi",
        "-v", "${workspace}:/workspace",
        "-w", "/workspace"
    )

    $dockerArgs += @("codex")
    $dockerArgs += $Command

    docker @dockerArgs
}

function codex-docker {
    Invoke-CodexDocker (@("codex") + $args)
}

function codex-shell {
    Invoke-CodexDocker (@("bash") + $args)
}

function pi-docker {
    Invoke-CodexDocker (@("pi") + $args)
}
```

The `codex-home` Docker volume keeps Codex login/config state between container runs, and the `pi-home` Docker volume keeps Pi login/config state between container runs. These named volumes avoid Windows bind-mount permission issues.
On startup, the container ensures `/home/codex/.codex` and `/home/codex/.pi` are owned by the `codex` user before launching the CLI. This avoids TUI startup failures caused by config files or Docker volumes with the wrong owner.

Reload your profile:

```powershell
. $PROFILE
```

Then run Codex from any folder:

```powershell
codex-docker
```

Start a shell in the container when you want to choose between `codex`, `pi`, and other installed tools:

```powershell
codex-shell
```

Run `pi` directly:

```powershell
pi-docker
```

Pi starts with `pi-subagents` enabled by default. The image installs the npm package globally, and the entrypoint adds `npm:pi-subagents` to `/home/codex/.pi/agent/settings.json` when it is missing. This matters when you mount the `pi-home` volume, because the mounted volume replaces the Pi settings that were present when the image was built.

To disable the automatic package entry for a run:

```powershell
docker run --rm -it `
  -e PI_PACKAGES="" `
  -v "pi-home:/home/codex/.pi" `
  codex pi
```

You can also pass Codex CLI arguments through:

```powershell
codex-docker --version
codex-docker "explain this repo"
```

## Bash Helper

Add these functions to your shell profile, such as `~/.bashrc` or `~/.bash_profile`, to start tools in Docker from the folder you are currently in:

```bash
invoke_codex_docker() {
    local command=("$@")
    if [ "$#" -eq 0 ]; then
        command=("codex")
    fi

    local workspace
    workspace="$(pwd)"
    local codex_volume="codex-home"
    local pi_volume="pi-home"

    docker run --rm -it \
        -e OPENAI_API_KEY \
        -v "${codex_volume}:/home/codex/.codex" \
        -v "${pi_volume}:/home/codex/.pi" \
        -v "${workspace}:/workspace" \
        -w /workspace \
        codex \
        "${command[@]}"
}

codex-docker() {
    invoke_codex_docker codex "$@"
}

codex-shell() {
    invoke_codex_docker bash "$@"
}

pi-docker() {
    invoke_codex_docker pi "$@"
}
```

The `codex-home` Docker volume keeps Codex login/config state between container runs, and the `pi-home` Docker volume keeps Pi login/config state between container runs. These named volumes avoid host bind-mount permission issues.
On startup, the container ensures `/home/codex/.codex` and `/home/codex/.pi` are owned by the `codex` user before launching the CLI. This avoids TUI startup failures caused by config files or Docker volumes with the wrong owner.

Reload your profile:

```bash
source ~/.bashrc
```

Then run Codex from any folder:

```bash
codex-docker
```

Start a shell in the container when you want to choose between `codex`, `pi`, and other installed tools:

```bash
codex-shell
```

Run `pi` directly:

```bash
pi-docker
```

Pi starts with `pi-subagents` enabled by default. The image installs the npm package globally, and the entrypoint adds `npm:pi-subagents` to `/home/codex/.pi/agent/settings.json` when it is missing. This matters when you mount the `pi-home` volume, because the mounted volume replaces the Pi settings that were present when the image was built.

To disable the automatic package entry for a run:

```bash
docker run --rm -it \
    -e PI_PACKAGES="" \
    -v "pi-home:/home/codex/.pi" \
    codex pi
```

You can also pass Codex CLI arguments through:

```bash
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
- The `PI_PACKAGES` environment variable controls the Pi packages that the entrypoint ensures in global Pi settings. It defaults to `npm:pi-subagents`.

## License

Add a license before publishing or distributing this repository.
