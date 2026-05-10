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

Useful build arguments:

```sh
docker build \
  --build-arg USER_UID="$(id -u)" \
  --build-arg USER_GID="$(id -g)" \
  --build-arg CODEX_VERSION=latest \
  --build-arg CODEX_SHA256="" \
  --build-arg POWERSHELL_VERSION=7.6.0 \
  --build-arg POWERSHELL_SHA256="" \
  --build-arg PI_PACKAGES="npm:pi-subagents" \
  -t codex src
```

The default image tracks current upstream inputs (`debian:trixie-slim`, latest Codex, and current npm packages), so builds are convenient but not byte-for-byte reproducible. Pin the base image, `CODEX_VERSION`, npm package versions, and downloaded checksums if you need fully reproducible builds. Set `CODEX_SHA256` or `POWERSHELL_SHA256` to a non-empty SHA-256 digest to verify those downloaded artifacts during the build.

`PI_PACKAGES` sets the default packages that the entrypoint seeds into `/home/codex/.pi/agent/settings.json` at container startup. It does not change the npm packages installed into the image during `docker build`.

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

Environment variables passed with `-e` are visible to Docker administrators and may appear in container metadata. For less secret exposure, prefer interactive Codex login and persist `/home/codex/.codex` with a named volume. The shell helpers below ask Git to resolve the commit identity for the current project, including repo-local and conditional include config, then pass only the resolved name/email instead of mounting your host `~/.gitconfig`.

On Linux, the container command runs as user `codex` (UID/GID `1001` by default). If your bind-mounted project is owned by another UID, writes in `/workspace` may fail. Rebuild with matching `USER_UID` and `USER_GID` as shown above, or adjust the host directory permissions.

The `codex` user has passwordless `sudo` inside the container for development convenience. Treat read-write bind mounts as writable by a privileged container process, and only mount projects you intend the agent to modify.

## Shell Helpers

For regular use, put a small wrapper in your shell profile so the current directory is always mounted as `/workspace`.

PowerShell:

```powershell
function Invoke-CodexDocker {
    param([string[]]$Command = @("codex"))

    $envArgs = @("-e", "OPENAI_API_KEY")
    $gitIdent = git var GIT_AUTHOR_IDENT 2>$null
    if ($LASTEXITCODE -eq 0 -and $gitIdent -match '^(?<name>.+) <(?<email>[^<>]+)> \d+ [+-]\d+$') {
        $envArgs += @(
            "-e", "GIT_AUTHOR_NAME=$($Matches.name)",
            "-e", "GIT_AUTHOR_EMAIL=$($Matches.email)",
            "-e", "GIT_COMMITTER_NAME=$($Matches.name)",
            "-e", "GIT_COMMITTER_EMAIL=$($Matches.email)"
        )
    }

    $dockerArgs = @(
        "run", "--rm", "-it"
    ) + $envArgs + @(
        "-v", "codex-home:/home/codex/.codex",
        "-v", "pi-home:/home/codex/.pi",
        "-v", "${PWD}:/workspace",
        "-w", "/workspace",
        "codex"
    ) + $Command

    docker @dockerArgs
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

    local env_args=(-e OPENAI_API_KEY)
    local git_ident git_name git_email
    if git_ident="$(git var GIT_AUTHOR_IDENT 2>/dev/null)"; then
        git_name="${git_ident% <*}"
        git_email="${git_ident#* <}"
        git_email="${git_email%%>*}"
        if [ -n "${git_name}" ] && [ -n "${git_email}" ]; then
            env_args+=(
                -e "GIT_AUTHOR_NAME=${git_name}"
                -e "GIT_AUTHOR_EMAIL=${git_email}"
                -e "GIT_COMMITTER_NAME=${git_name}"
                -e "GIT_COMMITTER_EMAIL=${git_email}"
            )
        fi
    fi

    docker run --rm -it \
        "${env_args[@]}" \
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

If `/home/codex/.pi/agent/settings.json` already exists but is not valid JSON, or has a non-array `packages` value, startup stops with an error so the mounted settings file can be fixed or removed before package seeding continues.

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

Optional smoke checks after building:

```sh
docker run --rm codex codex --version
docker run --rm codex pi --version
docker run --rm -e PI_PACKAGES="npm:pi-subagents" codex bash -lc 'jq -e ".packages | index(\"npm:pi-subagents\")" /home/codex/.pi/agent/settings.json'
```

## License

MIT. See [LICENSE](./LICENSE).
