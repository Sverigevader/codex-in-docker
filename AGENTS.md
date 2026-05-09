# Repository Guidelines for Agents

## Project Overview

This repository builds a Docker image for running Codex in an isolated, reproducible container environment. The main implementation lives in `src/`, with supporting documentation in the repository root.

## Repository Layout

- `src/Dockerfile`: Docker image definition.
- `src/codex-entrypoint.sh`: Container entrypoint behavior.
- `README.md`: User-facing build, run, and PowerShell helper documentation.

## Common Commands

From the repository root:

```sh
docker build -t codex src
```

From inside `src/`:

```sh
docker build -t codex .
```

Run the image:

```sh
docker run --rm -it codex
```

## Editing Guidance

- Keep Dockerfile changes small and explicit.
- Update `README.md` when changing build arguments, runtime behavior, required environment variables, mounted paths, or helper commands.
- Keep shell scripts POSIX-compatible unless there is a clear reason to require a specific shell.
- Preserve LF line endings for files used inside the Linux container.
- Do not commit generated files, local environment files, editor metadata, or credentials.

## Validation

For Docker or entrypoint changes, build the image before considering the change complete:

```sh
docker build -t codex src
```

For documentation-only changes, review the rendered Markdown and confirm commands remain copy-pasteable.
