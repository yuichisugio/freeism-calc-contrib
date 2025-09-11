#!/bin/bash

#--------------------------------------
# fork関連のデータ取得を行うファイル
#--------------------------------------

set -euo pipefail

# ページ単位の生レスポンスを置く一時JSON
readonly RAW_FORK_PER_PAGE_JSON="./src/designated-oss-growth/github-developer-contrib/archive/fork/raw-fork-per-page.json"
# RAWデータをためるJSONL
readonly RAW_FORK_ALL_JSONL_PATH="./src/designated-oss-growth/github-developer-contrib/archive/fork/raw-fork-all.jsonl"
# 1行=1ノードで貯めるJSONL（中間）
readonly RAW_FORK_JSONL_PATH="./src/designated-oss-growth/github-developer-contrib/archive/fork/raw-fork.jsonl"
# 最終成果物（配列JSON）
readonly RESULTS_FORK_JSON_PATH="./src/designated-oss-growth/github-developer-contrib/archive/fork/results-fork.json"

mkdir -p "$(dirname "$RAW_FORK_PER_PAGE_JSON")"

get_fork() {
  # 引数のデフォルト値
  local OWNER="ryoppippi"
  local REPO="ccusage"
  local START="1970-01-01T00:00:00Z"
  local END
  END="$(date -u +%Y-%m-%dT23:59:59Z)"
  local CURSOR
  local QUERY
  local HAS_NEXT
  local LAST_DATE

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

  # ISO 8601 に正規化（文字列比較で時系列順に一致する）
  [[ "$START" == *T* ]] || START="${START}T00:00:00Z"
  [[ "$END" == *T* ]] || END="${END}T23:59:59Z"

  # GraphQL クエリ
  # shellcheck disable=SC2016
  QUERY='
    query($owner: String!, $name: String!, $endCursor: String) {
      repository(owner: $owner, name: $name) {
        forkCount
        forks(first: 100, after: $endCursor, orderBy: { field: CREATED_AT, direction: ASC }) {
          totalCount
          pageInfo { hasNextPage endCursor }
          nodes {
            createdAt
            owner {
              __typename
              login
              id
              ... on User { databaseId }
              ... on Organization { databaseId }
            }
          }
        }
      }
    }
  '

  : >"$RAW_FORK_JSONL_PATH"     # 中間ファイルを空に
  : >"$RAW_FORK_ALL_JSONL_PATH" # 何度も実行したときに追記しないように全データを保存のために貯めるJSONLを空に

  while :; do
    gh api graphql \
      -F owner="$OWNER" -F name="$REPO" -F endCursor="$CURSOR" \
      -f query="$QUERY" | jq '.' >"$RAW_FORK_PER_PAGE_JSON"

    # 全データを保存のために貯めるJSONLに追記
    cat "$RAW_FORK_PER_PAGE_JSON" >>"$RAW_FORK_ALL_JSONL_PATH"

    # 期間で絞ってJSONLに追記
    jq -r --arg START "$START" --arg END "$END" '
      .data.repository.forks.nodes[]
      | select(.createdAt >= $START and .createdAt <= $END)
    ' "$RAW_FORK_PER_PAGE_JSON" >>"$RAW_FORK_JSONL_PATH"

    # 次ページの準備
    HAS_NEXT="$(jq -r '.data.repository.forks.pageInfo.hasNextPage' "$RAW_FORK_PER_PAGE_JSON")"
    CURSOR="$(jq -r '.data.repository.forks.pageInfo.endCursor' "$RAW_FORK_PER_PAGE_JSON")"
    LAST_DATE="$(jq -r '(.data.repository.forks.nodes | last | .createdAt) // empty' "$RAW_FORK_PER_PAGE_JSON")"

    # 続きがない、もしくは期間外の場合は終了
    if [[ "$HAS_NEXT" != "true" || "$CURSOR" == "null" || -z "$CURSOR" ]] || [[ -n "$LAST_DATE" && "$LAST_DATE" > "$END" ]]; then
      break
    fi
  done

  # 最後に配列化して成果物（※入力と出力は別ファイルにする！）
  jq -s '.' "$RAW_FORK_JSONL_PATH" >"$RESULTS_FORK_JSON_PATH"
}

get_ratelimit() {
  printf '%s\n' "$(gh api graphql -f query='
  query { rateLimit { remaining } }
  ' --jq '.data.rateLimit.remaining')"
}

printf 'before-fork-remaining:%s\n' "$(get_ratelimit)"
get_fork "$@"
printf 'success\n'
printf 'after-fork-remaining:%s\n' "$(get_ratelimit)"
