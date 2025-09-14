#!/bin/bash

#--------------------------------------
# star関連のデータ取得を行うファイル
#--------------------------------------

set -euo pipefail

# ページ単位の生レスポンスを置く一時JSON
readonly RAW_STAR_PER_PAGE_JSON="./src/designated-oss-growth/github-developer-contrib/archive/star/raw-star-per-page.json"
# RAWデータをためるJSONL
readonly RAW_STAR_ALL_JSONL_PATH="./src/designated-oss-growth/github-developer-contrib/archive/star/raw-star-all.jsonl"
# 1行=1ノードで貯めるJSONL（中間）
readonly RAW_STAR_JSONL_PATH="./src/designated-oss-growth/github-developer-contrib/archive/star/raw-star.jsonl"
# 最終成果物（配列JSON）
readonly RESULTS_STAR_JSON_PATH="./src/designated-oss-growth/github-developer-contrib/archive/star/results-star.json"

mkdir -p "$(dirname "$RAW_STAR_PER_PAGE_JSON")"

function get_star() {
  # 引数のデフォルト値
  local OWNER="ryoppippi"
  local REPO="ccusage"
  local START="1970-01-01T00:00:00Z"
  local END
  local CURSOR
  local QUERY
  local HAS_NEXT
  local LAST_DATE
  END="$(date -u +%Y-%m-%dT23:59:59Z)"

  # --- 引数パース。引数がある場合はデフォルト値を上書きする ---
  while [[ $# -gt 0 ]]; do
    case "$1" in
    -o | --owner)
      OWNER="$2"
      shift 2
      ;;
    -r | --repo)
      REPO="$2"
      shift 2
      ;;
    -s | --start)
      START="$2"
      shift 2
      ;;
    -e | --end)
      END="$2"
      shift 2
      ;;
    *)
      printf '%s\n' "Unknown option: $1" >&2
      exit 1
      ;;
    esac
  done

  # ISO 8601 に正規化
  [[ "$START" == *T* ]] || START="${START}T00:00:00Z"
  [[ "$END" == *T* ]] || END="${END}T23:59:59Z"

  # GraphQL クエリ
  # shellcheck disable=SC2016
  QUERY='
    query($owner: String!, $name: String!, $endCursor: String) {
      repository(owner: $owner, name: $name) {
        stargazerCount
        stargazers(first:100, after:$endCursor, orderBy:{field: STARRED_AT, direction: ASC}) {
          totalCount
          pageInfo { hasNextPage endCursor }
          edges {
            starredAt
            node {
              login
              id
              databaseId
            }
          }
        }
      }
    }
  '

  : >"$RAW_STAR_JSONL_PATH"     # 中間ファイルを空に
  : >"$RAW_STAR_ALL_JSONL_PATH" # 何度も実行したときに追記しないように全データを保存のために貯めるJSONLを空に

  while :; do
    gh api graphql \
      -F owner="$OWNER" -F name="$REPO" -F endCursor="$CURSOR" \
      -f query="$QUERY" | jq '.' >"$RAW_STAR_PER_PAGE_JSON"

    # 全データを保存のために貯めるJSONLに追記
    cat "$RAW_STAR_PER_PAGE_JSON" >>"$RAW_STAR_ALL_JSONL_PATH"

    # 期間で絞ってJSONLに追記
    jq -r --arg START "$START" --arg END "$END" '
      .data.repository.stargazers.edges[]
      | select(.starredAt >= $START and .starredAt <= $END)
    ' "$RAW_STAR_PER_PAGE_JSON" >>"$RAW_STAR_JSONL_PATH"

    # 次ページの準備
    HAS_NEXT="$(jq -r '.data.repository.stargazers.pageInfo.hasNextPage' "$RAW_STAR_PER_PAGE_JSON")"
    CURSOR="$(jq -r '.data.repository.stargazers.pageInfo.endCursor' "$RAW_STAR_PER_PAGE_JSON")"
    LAST_DATE="$(jq -r '(.data.repository.stargazers.edges | last | .starredAt) // empty' "$RAW_STAR_PER_PAGE_JSON")"

    # 続きがない、もしくは期間外の場合は終了
    if [[ "$HAS_NEXT" != "true" || "$CURSOR" == "null" || -z "$CURSOR" ]] || [[ -n "$LAST_DATE" && "$LAST_DATE" > "$END" ]]; then
      break
    fi
  done

  # 最後に配列化して成果物（※入力と出力は別ファイルにする！）
  jq -s '.' "$RAW_STAR_JSONL_PATH" >"$RESULTS_STAR_JSON_PATH"
}

get_ratelimit() {
  printf '%s\n' "$(gh api graphql -f query='
  query { rateLimit { remaining } }
  ' --jq '.data.rateLimit.remaining')"
}

printf 'before-star-remaining:%s\n' "$(get_ratelimit)"
get_star "$@"
printf 'success\n'
printf 'after-star-remaining:%s\n' "$(get_ratelimit)"
