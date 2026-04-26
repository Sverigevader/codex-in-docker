FROM debian:bookworm-slim

ARG USERNAME=codex
ARG USER_UID=1001
ARG USER_GID=1001
ARG TARGETARCH
ARG CODEX_VERSION=latest

ENV DEBIAN_FRONTEND=noninteractive \
    CODEX_USER=codex \
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
        openssh-client \
        procps \
        python3 \
        python3-pip \
        ripgrep \
        sudo \
        tar \
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
RUN chmod 0755 /usr/local/bin/codex-entrypoint

RUN groupadd --gid "${USER_GID}" "${USERNAME}" \
    && useradd --uid "${USER_UID}" --gid "${USER_GID}" --create-home --shell /bin/bash "${USERNAME}" \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}" \
    && chmod 0440 "/etc/sudoers.d/${USERNAME}" \
    && mkdir -p /workspace \
    && chown -R "${USERNAME}:${USERNAME}" /workspace

WORKDIR /workspace

RUN mkdir -p "/home/${USERNAME}/.codex" \
    && chown -R "${USERNAME}:${USERNAME}" "/home/${USERNAME}/.codex" \
    && codex --version

ENTRYPOINT ["codex-entrypoint"]
CMD ["codex"]
