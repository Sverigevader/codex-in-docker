#!/usr/bin/env bash
set -euo pipefail

codex_user="${CODEX_USER:-codex}"
user_home="/home/${codex_user}"
codex_home="${CODEX_HOME:-${user_home}/.codex}"
pi_home="${PI_HOME:-${user_home}/.pi}"
pi_agent_dir="${PI_CODING_AGENT_DIR:-${pi_home}/agent}"

if [[ "$(id -u)" == "0" ]]; then
    mkdir -p "${codex_home}"
    mkdir -p "${pi_home}"

    if ! chown -R "${codex_user}:${codex_user}" "${codex_home}" 2>/dev/null; then
        echo "WARNING: could not update ownership for ${codex_home}; Codex may not be able to persist login/config state." >&2
    fi

    if ! chown -R "${codex_user}:${codex_user}" "${pi_home}" 2>/dev/null; then
        echo "WARNING: could not update ownership for ${pi_home}; Pi may not be able to persist login/config state." >&2
    fi

    exec sudo -E -H -u "${codex_user}" -- "$0" "$@"
fi

export HOME="${user_home}"
export CODEX_HOME="${codex_home}"
export PI_CODING_AGENT_DIR="${pi_agent_dir}"

if [[ "${1:-codex}" == "codex" && -z "${OPENAI_API_KEY:-}" ]]; then
    cat >&2 <<'EOF'
OPENAI_API_KEY is not set.

Codex can still run, but you will need to authenticate interactively.
Follow the device-code login instructions shown by the Codex CLI.

To skip interactive login, rerun the container with:
  docker run --rm -it -e OPENAI_API_KEY codex
EOF
fi

exec "$@"
