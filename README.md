# Codex Docker

Run Codex and Pi inside a disposable Linux container, while keeping your host machine clean.

The point of this image is not just reproducibility. It gives coding agents a place to work that is separate from your everyday shell, npm cache, editor state, and filesystem permissions. Your project is mounted into `/workspace`; Codex and Pi get persistent named volumes for their own login and settings; everything else can disappear when the container exits.

## Why

Coding agents are most useful when they can run commands, inspect projects, and install the tools a repository needs. That is also exactly why it is nice to give them a clear boundary.

This image provides:

- a Linux environment for Codex and Pi, even from Windows
- named Docker volumes for Codex and Pi auth/config state
- common development tools without touching the host
- Bubblewrap support for Codex sandboxing
- Pi with `pi-subagents` already available

The result is a small routine: enter a project folder, start the container, work with the agent, leave no toolchain mess behind.

## Build

```sh
docker build -t codex src
```

## Use It

Run Codex directly:

```sh
docker run --rm -it codex
```

Most of the time you want to mount the current project and persist agent state:

```sh
docker run --rm -it \
  -e OPENAI_API_KEY \
  -v codex-home:/home/codex/.codex \
  -v pi-home:/home/codex/.pi \
  -v "$(pwd):/workspace" \
  -w /workspace \
  codex
```

On Windows PowerShell:

```powershell
docker run --rm -it `
  -e OPENAI_API_KEY `
  -v codex-home:/home/codex/.codex `
  -v pi-home:/home/codex/.pi `
  -v "${PWD}:/workspace" `
  -w /workspace `
  codex
```

If `OPENAI_API_KEY` is not set, Codex can still authenticate interactively.

## Shell Helpers

For regular use, put a small wrapper in your shell profile so the current directory is always mounted as `/workspace`.

PowerShell:

```powershell
function Invoke-CodexDocker {
    param([string[]]$Command = @("codex"))

    docker run --rm -it `
        -e OPENAI_API_KEY `
        -v codex-home:/home/codex/.codex `
        -v pi-home:/home/codex/.pi `
        -v "${PWD}:/workspace" `
        -w /workspace `
        codex `
        @Command
}

function codex-docker { Invoke-CodexDocker (@("codex") + $args) }
function codex-shell { Invoke-CodexDocker (@("bash") + $args) }
function pi-docker { Invoke-CodexDocker (@("pi") + $args) }
```

Bash:

```bash
invoke_codex_docker() {
    local command=("$@")
    if [ "$#" -eq 0 ]; then
        command=("codex")
    fi

    docker run --rm -it \
        -e OPENAI_API_KEY \
        -v codex-home:/home/codex/.codex \
        -v pi-home:/home/codex/.pi \
        -v "$(pwd):/workspace" \
        -w /workspace \
        codex \
        "${command[@]}"
}

codex-docker() { invoke_codex_docker codex "$@"; }
codex-shell() { invoke_codex_docker bash "$@"; }
pi-docker() { invoke_codex_docker pi "$@"; }
```

Then from any project:

```sh
codex-docker
pi-docker
codex-shell
```

## Pi Packages

Pi starts with `pi-subagents` enabled. The Docker image installs the npm package, and the entrypoint makes sure `npm:pi-subagents` exists in `/home/codex/.pi/agent/settings.json`.

That startup step matters because the `pi-home` Docker volume replaces anything baked into `/home/codex/.pi` at image build time.

To change the default package list:

```sh
docker run --rm -it \
  -e PI_PACKAGES="npm:pi-subagents npm:pi-web-access" \
  -v pi-home:/home/codex/.pi \
  codex pi
```

To disable automatic Pi package seeding for one run:

```sh
docker run --rm -it -e PI_PACKAGES="" codex pi
```

## What's Inside

- Codex CLI from the official Linux release binary
- Pi Coding Agent from npm
- `pi-subagents`
- Git and Git LFS
- PowerShell Core
- Bubblewrap
- Python 3, Node.js, npm, build tools, and common shell utilities

## Repository Layout

```text
.
├── src/
│   ├── Dockerfile
│   └── codex-entrypoint.sh
└── README.md
```

## Development

Keep Dockerfile changes small and explicit. If build args, mounted paths, startup behavior, environment variables, or helper commands change, update this README.

For Docker or entrypoint changes, validate with:

```sh
docker build -t codex src
```

## License

MIT. See [LICENSE](./LICENSE).
