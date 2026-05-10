#!/usr/bin/env bash
set -euo pipefail

codex_user="${CODEX_USER:-codex}"
user_home="/home/${codex_user}"
codex_home="${CODEX_HOME:-${user_home}/.codex}"
pi_home="${PI_HOME:-${user_home}/.pi}"
pi_agent_dir="${PI_CODING_AGENT_DIR:-${pi_home}/agent}"
pi_packages="${PI_PACKAGES-npm:pi-subagents}"

ensure_owned_home_dir() {
    local path="$1"
    local label="$2"
    local canonical_path canonical_home

    canonical_path="$(realpath -m -- "${path}")"
    canonical_home="$(realpath -m -- "${user_home}")"

    case "${canonical_path}" in
        "${canonical_home}"|"${canonical_home}"/*) ;;
        *)
            echo "WARNING: ${label} path ${path} resolves outside ${user_home}; not creating or changing ownership as root." >&2
            return 0
            ;;
    esac

    mkdir -p "${canonical_path}"
    if ! chown -R "${codex_user}:${codex_user}" "${canonical_path}" 2>/dev/null; then
        echo "WARNING: could not update ownership for ${canonical_path}; ${label} may not be able to persist login/config state." >&2
    fi
}

ensure_writable_dir() {
    local path="$1"
    local label="$2"

    if ! mkdir -p "${path}" 2>/dev/null; then
        echo "ERROR: could not create ${label} directory ${path}. Check the mounted path and permissions." >&2
        exit 1
    fi
    if [[ ! -w "${path}" ]]; then
        echo "ERROR: ${label} directory ${path} is not writable by user $(id -un). Check the mounted path and permissions." >&2
        exit 1
    fi
}

if [[ "$(id -u)" == "0" ]]; then
    ensure_owned_home_dir "${codex_home}" "Codex"
    ensure_owned_home_dir "${pi_home}" "Pi"

    exec sudo -E -H -u "${codex_user}" -- "$0" "$@"
fi

export HOME="${user_home}"
export CODEX_HOME="${codex_home}"
export PI_CODING_AGENT_DIR="${pi_agent_dir}"

ensure_writable_dir "${pi_agent_dir}" "Pi agent"
settings_file="${pi_agent_dir}/settings.json"
if [[ -n "${pi_packages}" ]]; then
    if [[ ! -f "${settings_file}" ]]; then
        printf '{"packages":[]}\n' > "${settings_file}"
    elif ! jq empty "${settings_file}" >/dev/null 2>&1; then
        echo "ERROR: ${settings_file} is not valid JSON; fix or remove it before starting Pi package seeding." >&2
        exit 1
    elif ! jq -e '(.packages == null) or (.packages | type == "array")' "${settings_file}" >/dev/null; then
        echo "ERROR: ${settings_file} must have a .packages array before Pi package seeding can continue." >&2
        exit 1
    fi

    for pi_package in ${pi_packages}; do
        if ! jq -e --arg package "${pi_package}" '
            (.packages // []) | any(
                if type == "string" then
                    . == $package
                else
                    .source == $package
                end
            )
        ' "${settings_file}" >/dev/null; then
            tmp_settings="$(mktemp)"
            jq --arg package "${pi_package}" '
                .packages = ((.packages // []) + [$package])
            ' "${settings_file}" > "${tmp_settings}"
            mv "${tmp_settings}" "${settings_file}"
        fi
    done
fi

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
