#!/usr/bin/env bash
# cutover.sh — one-shot script to push the local Goal Atlas DB + stylized
# portraits to the freshly-deployed Hetzner box.
#
# Prereqs:
#   - bin/kamal setup completed successfully
#   - Postgres accessory `goal_atlas-db` is running on the box
#   - The Rails app is up (or at least the DB accessory is)
#
# Usage:
#   set -a; source .env; set +a
#   ./script/cutover.sh

set -euo pipefail

REMOTE_HOST="root@5.161.109.253"
SSH_KEY="${HOME}/.ssh/id_ed25519_tuxnotfound"
LOCAL_DB="goal_atlas_development"
REMOTE_DB="goal_atlas_production"
DB_USER="goal_atlas"
DUMP_FILE="/tmp/goal_atlas_$(date +%Y%m%d_%H%M%S).dump"
REMOTE_DUMP="/root/goal_atlas.dump"
PG_BIN="/opt/homebrew/opt/postgresql@16/bin"
LOCAL_PORTRAITS="${PWD}/storage/stylized_portraits/"
REMOTE_VOLUME="/var/lib/docker/volumes/goal_atlas_storage/_data/stylized_portraits/"

if [[ -z "${GOAL_ATLAS_DATABASE_PASSWORD:-}" ]]; then
  echo "GOAL_ATLAS_DATABASE_PASSWORD not set — source your .env first." >&2
  exit 1
fi

# ---------- 1. Dump local DB ----------------------------------------------
echo ">>> Dumping local $LOCAL_DB → $DUMP_FILE"
"${PG_BIN}/pg_dump" \
  --format=custom \
  --no-owner \
  --no-acl \
  --exclude-schema='solid_*' \
  --exclude-table-data='sessions' \
  --file="$DUMP_FILE" \
  "$LOCAL_DB"

du -sh "$DUMP_FILE"

# ---------- 2. Ship dump to box -------------------------------------------
echo ">>> SCP dump → ${REMOTE_HOST}:${REMOTE_DUMP}"
scp -i "$SSH_KEY" "$DUMP_FILE" "${REMOTE_HOST}:${REMOTE_DUMP}"

# ---------- 3. Restore on prod --------------------------------------------
echo ">>> Restoring dump into ${REMOTE_DB} on box"
ssh -i "$SSH_KEY" "$REMOTE_HOST" bash -s <<EOF
set -euo pipefail

# Stop the app so it doesn't fight the DB during restore.
docker stop \$(docker ps -q --filter "name=goal_atlas-web") 2>/dev/null || true

# Drop + recreate the DB (matches schema.rb cleanly).
docker exec -e PGPASSWORD='${GOAL_ATLAS_DATABASE_PASSWORD}' goal_atlas-db \
  psql -U ${DB_USER} -d postgres -c "DROP DATABASE IF EXISTS ${REMOTE_DB};"
docker exec -e PGPASSWORD='${GOAL_ATLAS_DATABASE_PASSWORD}' goal_atlas-db \
  psql -U ${DB_USER} -d postgres -c "CREATE DATABASE ${REMOTE_DB} OWNER ${DB_USER};"

# Restore — copy dump INTO the postgres container then pg_restore.
docker cp ${REMOTE_DUMP} goal_atlas-db:/tmp/goal_atlas.dump
docker exec -e PGPASSWORD='${GOAL_ATLAS_DATABASE_PASSWORD}' goal_atlas-db \
  pg_restore --no-owner --no-acl -U ${DB_USER} -d ${REMOTE_DB} /tmp/goal_atlas.dump
docker exec goal_atlas-db rm -f /tmp/goal_atlas.dump
rm -f ${REMOTE_DUMP}

# Bring the app back up.
docker start \$(docker ps -aq --filter "name=goal_atlas-web") 2>/dev/null || true
EOF

# ---------- 4. Rsync stylized portraits -----------------------------------
echo ">>> Rsync stylized portraits → ${REMOTE_HOST}:${REMOTE_VOLUME}"
ssh -i "$SSH_KEY" "$REMOTE_HOST" "mkdir -p '${REMOTE_VOLUME}'"
# Use -P (=--partial --progress) instead of --info=progress2 because macOS
# ships an ancient rsync (2.6.9) that lacks the latter flag.
rsync -avhP \
  -e "ssh -i ${SSH_KEY}" \
  "$LOCAL_PORTRAITS" \
  "${REMOTE_HOST}:${REMOTE_VOLUME}"

# The app container runs as uid 1000 (rails user); rsync as root preserves
# the local owner instead, leaving the dir unwritable to the app. Re-chown so
# PortraitStylizer can write new portraits.
ssh -i "$SSH_KEY" "$REMOTE_HOST" "chown -R 1000:1000 '${REMOTE_VOLUME}'"

# ---------- 5. Smoke test --------------------------------------------------
echo ">>> Curling https://thegoalatlas.com/up"
curl -sS -o /dev/null -w "HTTP %{http_code}\n" "https://thegoalatlas.com/up" || \
  echo "  (HTTPS not ready yet — Let's Encrypt cert may still be pending)"

curl -sS -o /dev/null -w "HTTP %{http_code} (HTTP)\n" "http://thegoalatlas.com/up" || true

echo ">>> Cutover complete."
