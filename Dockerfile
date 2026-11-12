ARG BASE
FROM ${BASE}

LABEL service=""

USER root

ARG TTYD_VERSION=1.7.7
RUN set -eux; \
    cd /tmp; \
    curl -fsSLO "https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/ttyd.x86_64"; \
    curl -fsSL "https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/SHA256SUMS" | grep ' ttyd.x86_64$' | sha256sum -c -; \
    install -m 0755 ttyd.x86_64 /usr/local/bin/ttyd; \
    rm ttyd.x86_64
RUN set -eux; \
    install -d -m 0755 /etc/apt/keyrings; \
    curl -fsSL https://repo.charm.sh/apt/gpg.key | gpg --dearmor -o /etc/apt/keyrings/charm.gpg; \
    echo 'deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *' > /etc/apt/sources.list.d/charm.list; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      chromium ffmpeg vhs lsof \
      fonts-dejavu-core fonts-liberation fonts-noto-color-emoji; \
    rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --no-cache-dir matplotlib numpy

ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:/usr/local/go/bin:$PATH
ARG RUST_TOOLCHAINS="stable 1.97.1"
RUN set -eux; \
    cd /tmp; \
    url=https://static.rust-lang.org/rustup/dist/x86_64-unknown-linux-gnu/rustup-init; \
    curl -fsSLO "$url"; \
    echo "$(curl -fsSL "$url.sha256" | cut -d' ' -f1)  rustup-init" | sha256sum -c -; \
    chmod +x rustup-init; \
    ./rustup-init -y -q --no-modify-path --profile minimal --default-toolchain none; \
    rm rustup-init; \
    for t in $RUST_TOOLCHAINS; do \
      rustup toolchain install "$t" --profile minimal --component rustfmt,clippy,rust-src; \
    done; \
    rustup default stable; \
    ln -sf "$CARGO_HOME"/bin/* /usr/local/bin/; \
    chown -R appuser:appgroup "$RUSTUP_HOME" "$CARGO_HOME"

ARG GO_VERSION=1.27.4
ARG GO_SHA256=7226736c2339719cda28fbf3a54d71aa63bcefe376e98cef00034268dab24840
RUN set -eux; \
    cd /tmp; \
    curl -fsSLo go.tgz "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"; \
    echo "${GO_SHA256}  go.tgz" | sha256sum -c -; \
    tar -C /usr/local -xzf go.tgz; \
    ln -sf /usr/local/go/bin/go /usr/local/go/bin/gofmt /usr/local/bin/; \
    rm go.tgz

# A second Node, 24, next to the base image's. Put /opt/node24/bin first on PATH to use it.
ARG NODE24_VERSION=24.19.0
ARG NODE24_SHA256=14b342e71204f811bde6153be8e04b62aef63c236fef92b55f9c83154b409647
RUN set -eux; \
    cd /tmp; \
    curl -fsSLo node.tar.xz "https://nodejs.org/dist/v${NODE24_VERSION}/node-v${NODE24_VERSION}-linux-x64.tar.xz"; \
    echo "${NODE24_SHA256}  node.tar.xz" | sha256sum -c -; \
    mkdir -p /opt/node24; \
    tar -C /opt/node24 --strip-components=1 -xJf node.tar.xz; \
    rm node.tar.xz; \
    /opt/node24/bin/node --version

ENV VHS_NO_SANDBOX=true

USER appuser
