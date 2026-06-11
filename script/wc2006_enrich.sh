#!/usr/bin/env bash
# One-shot WC2006 video-link enrichment.
# Steps:
#   1. Fill match-level YouTube highlights + propagate to goals
#   2. Run Gemini multimodal scout to assign goal timestamps
#   3. Cutover the enriched DB + portraits to prod
#
# Logs everything to /tmp/wc2006_enrich.log. Re-runnable; each rake task
# skips matches/goals that are already covered.

set -euo pipefail

LOG=/tmp/wc2006_enrich.log
export PATH="/Users/pedrocioga/.rbenv/shims:/usr/local/bin:$PATH"
cd "$(dirname "$0")/.."

# Load env (.env contains YOUTUBE_API_KEY, GEMINI_API_KEY, DB password)
set -a; source .env; set +a

exec >> "$LOG" 2>&1
echo
echo "============================================================"
echo "=== $(date -u +%Y-%m-%dT%H:%M:%SZ) — WC2006 enrich start ==="
echo "============================================================"

echo
echo ">>> Step 1: fill_youtube_highlights[2006,apply]"
bundle exec rake "video_links:fill_youtube_highlights[2006,apply]" || \
  echo "  fill_youtube_highlights ended non-zero (likely YouTube quota) — continuing."

echo
echo ">>> Step 2: gemini_apply_timestamps[2006,apply]"
bundle exec rake "video_links:gemini_apply_timestamps[2006,apply]" || \
  echo "  gemini_apply_timestamps ended non-zero — continuing."

echo
echo ">>> Step 3: cutover to prod"
./script/cutover.sh || \
  echo "  cutover failed — investigate manually."

echo
echo "============================================================"
echo "=== $(date -u +%Y-%m-%dT%H:%M:%SZ) — WC2006 enrich done ==="
echo "============================================================"
