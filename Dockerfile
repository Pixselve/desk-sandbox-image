ARG BASE
FROM ${BASE}

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
      chromium ffmpeg vhs \
      fonts-dejavu-core fonts-liberation fonts-noto-color-emoji; \
    rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --no-cache-dir matplotlib numpy

ENV VHS_NO_SANDBOX=true

USER appuser
