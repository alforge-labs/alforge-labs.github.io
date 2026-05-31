#!/usr/bin/env bash
#
# GitHub Releases のアセット DL 数を収集し、時系列 JSONL に追記しつつ
# shields.io endpoint バッジ用 JSON を再生成する。
#
# 使い方:
#   STATS_REPO=owner/repo GH_TOKEN=<token> bash collect_download_stats.sh <DATA_DIR>
#
#   - <DATA_DIR>/download-stats.jsonl : 1 行 1 スナップショットの時系列（追記）
#   - <DATA_DIR>/download-badge.json  : shields.io endpoint 形式（毎回上書き）
#
# 依存: gh, jq, python3（いずれも GitHub Actions ubuntu ランナーに同梱）
#
# 注意: GitHub の download_count は「リリースに添付したアセット」のみ計上され、
#       自動生成の Source code (zip/tar.gz) は対象外。累計値のためここでは
#       スナップショットを並べて自前で日次差分を出せるようにする。
set -euo pipefail

REPO="${STATS_REPO:-alforge-labs/alforge-labs.github.io}"
DATA_DIR="${1:-.}"
JSONL="${DATA_DIR}/download-stats.jsonl"
BADGE="${DATA_DIR}/download-badge.json"

mkdir -p "${DATA_DIR}"

ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
day="$(date -u +%Y-%m-%d)"

# 全リリース（draft 含む。draft アセットの download_count は 0）を取得。
releases_json="$(gh api "repos/${REPO}/releases" --paginate)"

# スナップショット 1 行を生成。
snapshot="$(printf '%s' "${releases_json}" | jq -c --arg ts "${ts}" --arg day "${day}" '
  {
    ts: $ts,
    date: $day,
    total: ([.[].assets[].download_count] | add // 0),
    by_tag: (map({ (.tag_name): ([.assets[].download_count] | add // 0) }) | add // {}),
    by_asset: [ .[] | .tag_name as $t | .assets[] | {tag: $t, name: .name, count: .download_count} ]
  }')"

echo "${snapshot}" >> "${JSONL}"

current_total="$(printf '%s' "${snapshot}" | jq '.total')"

# 7 日前以前で最も新しいスナップショットの total を取り、日次差分（7d）を出す。
# ISO 日付 (YYYY-MM-DD) は辞書順比較で日付順と一致する。
cutoff="$(python3 -c "import datetime; print((datetime.datetime.now(datetime.UTC).date() - datetime.timedelta(days=7)).isoformat())")"
prev_total="$(jq -rs --arg cutoff "${cutoff}" '
  [ .[] | select(.date <= $cutoff) ] | (last.total // empty)
' "${JSONL}" 2>/dev/null || true)"

if [ -n "${prev_total}" ]; then
  delta=$(( current_total - prev_total ))
  if [ "${delta}" -ge 0 ]; then sign="+"; else sign=""; fi
  message="${current_total} (${sign}${delta} / 7d)"
else
  # 7 日分の履歴がまだ無い（運用開始直後）。
  message="${current_total}"
fi

jq -n --arg msg "${message}" '{
  schemaVersion: 1,
  label: "downloads",
  message: $msg,
  color: "blue",
  namedLogo: "github"
}' > "${BADGE}"

echo "collected: total=${current_total} 7d_prev=${prev_total:-n/a} -> ${message}"
