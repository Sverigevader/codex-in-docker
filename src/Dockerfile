FROM debian:trixie-slim

ARG USERNAME=codex
ARG USER_UID=1001
ARG USER_GID=1001
ARG TARGETARCH
ARG CODEX_VERSION=latest
ARG POWERSHELL_VERSION=7.6.0

ENV DEBIAN_FRONTEND=noninteractive \
    CODEX_USER=${USERNAME} \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        bubblewrap \
        build-essential \
        ca-certificates \
        curl \
        fd-find \
        git \
        git-lfs \
        gnupg \
        iproute2 \
        jq \
        less \
        locales \
        nano \
        nodejs \
        npm \
        openssh-client \
        procps \
        python3 \
        python3-pip \
        ripgrep \
        sudo \
        tar \
        tmux \
        unzip \
        vim-tiny \
        wget \
        xz-utils \
        zip \
    && sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen \
    && ln -s /usr/bin/fdfind /usr/local/bin/fd \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    case "${TARGETARCH}" in \
        amd64) \
            powershell_asset="powershell_${POWERSHELL_VERSION}-1.deb_amd64.deb"; \
            wget -q "https://github.com/PowerShell/PowerShell/releases/download/v${POWERSHELL_VERSION}/${powershell_asset}" -O "/tmp/${powershell_asset}"; \
            apt-get update; \
            apt-get install -y --no-install-recommends "/tmp/${powershell_asset}"; \
            rm -f "/tmp/${powershell_asset}"; \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/*; \
            ;; \
        arm64) \
            powershell_asset="powershell-${POWERSHELL_VERSION}-linux-arm64.tar.gz"; \
            mkdir -p /opt/microsoft/powershell/7; \
            wget -q "https://github.com/PowerShell/PowerShell/releases/download/v${POWERSHELL_VERSION}/${powershell_asset}" -O "/tmp/${powershell_asset}"; \
            tar -xzf "/tmp/${powershell_asset}" -C /opt/microsoft/powershell/7; \
            chmod 0755 /opt/microsoft/powershell/7/pwsh; \
            ln -s /opt/microsoft/powershell/7/pwsh /usr/local/bin/pwsh; \
            rm -f "/tmp/${powershell_asset}"; \
            ;; \
        *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    pwsh --version

RUN npm install -g @earendil-works/pi-coding-agent

RUN set -eux; \
    case "${TARGETARCH}" in \
        amd64) codex_target="x86_64-unknown-linux-musl" ;; \
        arm64) codex_target="aarch64-unknown-linux-musl" ;; \
        *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    codex_asset="codex-${codex_target}.tar.gz"; \
    if [ "${CODEX_VERSION}" = "latest" ]; then \
        codex_url="https://github.com/openai/codex/releases/latest/download/${codex_asset}"; \
    else \
        codex_url="https://github.com/openai/codex/releases/download/rust-v${CODEX_VERSION}/${codex_asset}"; \
    fi; \
    curl -fsSL "${codex_url}" -o /tmp/codex.tar.gz; \
    tar -xzf /tmp/codex.tar.gz -C /tmp; \
    install -m 0755 "/tmp/codex-${codex_target}" /usr/local/bin/codex; \
    rm -f /tmp/codex.tar.gz "/tmp/codex-${codex_target}"; \
    codex --version

COPY codex-entrypoint.sh /usr/local/bin/codex-entrypoint
RUN chmod 0755 /usr/local/bin/codex-entrypoint \
    && printf '\nalias cls=clear\n' >> /etc/bash.bashrc \
    && printf 'set -g mouse on\n' >> /etc/tmux.conf

RUN groupadd --gid "${USER_GID}" "${USERNAME}" \
    && useradd --uid "${USER_UID}" --gid "${USER_GID}" --home-dir "/home/${USERNAME}" --create-home --shell /bin/bash "${USERNAME}" \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}" \
    && chmod 0440 "/etc/sudoers.d/${USERNAME}" \
    && mkdir -p /workspace \
    && chown -R "${USERNAME}:${USERNAME}" /workspace

ENV HOME=/home/${USERNAME} \
    CODEX_HOME=/home/${USERNAME}/.codex \
    PI_CODING_AGENT_DIR=/home/${USERNAME}/.pi/agent

WORKDIR /workspace

RUN mkdir -p "/home/${USERNAME}/.codex" "/home/${USERNAME}/.pi" \
    && chown -R "${USERNAME}:${USERNAME}" "/home/${USERNAME}/.codex" "/home/${USERNAME}/.pi" \
    && codex --version

ENTRYPOINT ["codex-entrypoint"]
CMD ["codex"]
