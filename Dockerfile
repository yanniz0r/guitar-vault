# ────────────────────────────────────────────────────────────────────────────
# Guitar Vault – production Docker image
#
# Persistent volumes expected at runtime (configure in Coolify):
#   /app/data     – SQLite database  (set DATABASE_PATH=/app/data/guitar_vault.db)
#   /app/uploads  – user-uploaded images
# ────────────────────────────────────────────────────────────────────────────

ARG ELIXIR_VERSION=1.18.3
ARG RUNNER_IMAGE="debian:bookworm-slim"

# ────────────────────────────────────────────────────────────────────────────
# Stage 1 – build the Mix release
# ────────────────────────────────────────────────────────────────────────────
FROM elixir:${ELIXIR_VERSION}-slim AS builder

RUN apt-get update -y \
    && apt-get install -y build-essential git \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force

ENV MIX_ENV="prod"

# Resolve dependencies first (layer-cached until mix.lock changes)
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV

# Compile dependencies with the prod config in place
RUN mkdir config
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

# Build digested front-end assets
COPY priv priv
COPY lib lib
COPY assets assets
RUN mix assets.deploy

# Compile the Elixir application
RUN mix compile

# Runtime config is intentionally copied after compile so it never
# influences compile-time macros (e.g. Application.compile_env)
COPY config/runtime.exs config/

# Assemble the self-contained OTP release
RUN mix release

# ────────────────────────────────────────────────────────────────────────────
# Stage 2 – minimal runtime image
# ────────────────────────────────────────────────────────────────────────────
FROM ${RUNNER_IMAGE}

# Runtime libraries required by the BEAM VM and the exqlite NIF
RUN apt-get update -y \
    && apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Erlang requires a UTF-8 locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

WORKDIR /app

# Create a dedicated non-root system user
RUN groupadd --system guitar_vault \
    && useradd --system --gid guitar_vault --home /app guitar_vault \
    && chown guitar_vault:guitar_vault /app

# Copy the compiled OTP release from the builder stage
COPY --from=builder --chown=guitar_vault:guitar_vault /app/_build/prod/rel/guitar_vault ./

# Copy the Docker entrypoint helper (wires up persistent volumes)
COPY --chown=guitar_vault:guitar_vault entrypoint.sh ./bin/entrypoint.sh
RUN chmod +x ./bin/entrypoint.sh

USER guitar_vault

ENV MIX_ENV=prod \
    PHX_SERVER=true

# Declare the two directories that must be backed by persistent volumes.
# In Coolify: add two volume mounts pointing to these paths.
VOLUME ["/app/data", "/app/uploads"]

EXPOSE 4000

ENTRYPOINT ["/app/bin/entrypoint.sh"]
CMD ["/app/bin/guitar_vault", "start"]
