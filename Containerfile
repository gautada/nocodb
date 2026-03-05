ARG CONTAINER_VERSION=13.3

# ╭――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――╮
# │ STAGE 1: Build NocoDB from source                                        │
# │                                                                          │
# │ Resolves the latest NocoDB release via the GitHub API, clones the        │
# │ monorepo at that tag, and builds the nocodb package with pnpm.           │
# │ Only the compiled dist/ and production node_modules are carried          │
# │ forward; all build tooling is left behind in this stage.                 │
# ╰――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――╯
FROM node:20-bookworm AS builder

ENV CI=true

RUN apt-get update \
 && apt-get install -y --no-install-recommends git jq curl python3 make g++ \
 && rm -rf /var/lib/apt/lists/*

RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /build

# Resolve the latest NocoDB release tag and clone at that version.
RUN IMAGE_VERSION=$(curl -sL "https://api.github.com/repos/nocodb/nocodb/releases/latest" \
      | jq -r '.tag_name' \
      | tr -d '[:space:]') \
 && { [ -n "$IMAGE_VERSION" ] && [ "$IMAGE_VERSION" != "null" ] \
      || { echo "ERROR: failed to resolve latest NocoDB release from GitHub API" >&2; exit 1; }; } \
 && echo "Building NocoDB ${IMAGE_VERSION}" \
 && git config --global advice.detachedHead false \
 && git clone --branch "$IMAGE_VERSION" --depth 1 \
      https://github.com/nocodb/nocodb.git .

# Install all dependencies, build the SDK (required by the backend),
# build the nocodb package (includes frontend), then prune to production-only dependencies.
RUN pnpm install --frozen-lockfile \
 && pnpm --filter nocodb-sdk build \
 && pnpm --filter nocodb build \
 && pnpm deploy --filter nocodb --prod /deploy \
 && test -f /build/packages/nocodb/docker/main.js

# ╭――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――╮
# │ STAGE 2: Final container image                                           │
# ╰――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――╯
FROM docker.io/gautada/debian:${CONTAINER_VERSION} AS container

ARG IMAGE_NAME=nocodb

# ╭――――――――――――――――――――╮
# │ METADATA           │
# ╰――――――――――――――――――――╯
LABEL org.opencontainers.image.title="${IMAGE_NAME}"
LABEL org.opencontainers.image.description="A NocoDB container built from source on gautada/debian."
LABEL org.opencontainers.image.url="https://hub.docker.com/r/gautada/${IMAGE_NAME}"
LABEL org.opencontainers.image.source="https://github.com/gautada/${IMAGE_NAME}"
LABEL org.opencontainers.image.license="AGPL-3.0"

# ╭――――――――――――――――――――╮
# │ PACKAGES           │
# ╰――――――――――――――――――――╯
# Install Node.js 20 LTS (via NodeSource) and jq for version scripts.
RUN apt-get update \
 && apt-get install -y --no-install-recommends jq curl \
 && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# ╭――――――――――――――――――――╮
# │ USER               │
# ╰――――――――――――――――――――╯
ARG USER=nocodb
RUN /usr/sbin/usermod -l $USER debian \
 && /usr/sbin/usermod -d /home/$USER -m $USER \
 && /usr/sbin/groupmod -n $USER debian \
 && /bin/echo "$USER:$USER" | /usr/sbin/chpasswd

# ╭――――――――――――――――――――╮
# │ APPLICATION        │
# ╰――――――――――――――――――――╯
# Copy the built nocodb docker bundle and production node_modules from the build stage.
# /deploy is created by `pnpm deploy` and contains a flat, self-contained node_modules.
COPY --from=builder /build/packages/nocodb/docker /usr/app/docker
COPY --from=builder /deploy/node_modules /usr/app/node_modules
COPY --from=builder /build/packages/nocodb/package.json /usr/app/package.json

# Create data directory for SQLite default backend and set ownership.
RUN mkdir -p /mnt/volumes/data \
 && chown -R $USER:$USER /usr/app /mnt/volumes/data

# ╭――――――――――――――――――――╮
# │ VERSION            │
# ╰――――――――――――――――――――╯
COPY version.sh /usr/bin/container-version
RUN chmod +x /usr/bin/container-version

# ╭――――――――――――――――――――╮
# │ LATEST             │
# ╰――――――――――――――――――――╯
COPY latest.sh /usr/bin/container-latest
RUN chmod +x /usr/bin/container-latest

# ╭――――――――――――――――――――╮
# │ HEALTH             │
# ╰――――――――――――――――――――╯
COPY appversion-check.sh /etc/container/health.d/appversion-check
RUN chmod +x /etc/container/health.d/appversion-check
COPY nocodb-running.sh /etc/container/health.d/nocodb-running
RUN chmod +x /etc/container/health.d/nocodb-running

# ╭――――――――――――――――――――╮
# │ ENTRYPOINT         │
# ╰――――――――――――――――――――╯
COPY nocodb.s6 /etc/services.d/nocodb/run
RUN chmod +x /etc/services.d/nocodb/run

VOLUME /mnt/volumes/data
EXPOSE 8080/tcp

WORKDIR /usr/app
