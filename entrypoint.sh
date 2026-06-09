#!/bin/sh
# entrypoint.sh – Docker startup helper for Guitar Vault
#
# Responsibilities:
#   1. Ensure the SQLite data directory exists (volume: /app/data)
#   2. Ensure the uploads directory exists (volume: /app/uploads)
#   3. Symlink the release's priv/uploads → /app/uploads so that
#      both GuitarVault.Uploads (writes files) and Plug.Static
#      (serves /uploads/*) both point at the same mounted volume.
#   4. Hand off to the application command (CMD).
#
# The Phoenix application's Ecto.Migrator runs migrations automatically
# on startup when RELEASE_NAME is set (see Application.start/2).

set -e

# ── 1. SQLite data directory ──────────────────────────────────────────────────
mkdir -p /app/data

# ── 2. Uploads directory on the persistent volume ────────────────────────────
mkdir -p /app/uploads

# ── 3. Symlink priv/uploads inside the release → /app/uploads ────────────────
# The release unpacks the OTP app under /app/lib/guitar_vault-<vsn>/priv/.
# Plug.Static is configured with `from: {:guitar_vault, "priv/uploads"}` which
# resolves to that priv directory at runtime. Symlinking it to /app/uploads
# keeps a single canonical location for the volume mount regardless of version.
PRIV_DIR=$(ls -d /app/lib/guitar_vault-*/priv 2>/dev/null | head -n1)

if [ -n "$PRIV_DIR" ]; then
  ln -sfn /app/uploads "${PRIV_DIR}/uploads"
fi

# ── 4. Exec the application ───────────────────────────────────────────────────
exec "$@"
