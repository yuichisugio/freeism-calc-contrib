#!/bin/bash

#--------------------------------------
# fork関連のデータ取得を行うファイル
#--------------------------------------

set -euo pipefail

readonly RAW_FORK_PATH="./src/designated-oss-growth/github-developer-contrib/archive/fork/raw-fork.jsonl"
readonly RESULTS_FORK_PATH="./src/designated-oss-growth/github-developer-contrib/archive/fork/results-fork.json"
mkdir -p "$(dirname "$RAW_FORK_PATH")" "$(dirname "$RESULTS_FORK_PATH")"

function get_fork() {
  local OWNER="${1:-ryoppippi}" REPO="${2:-ccusage}" CURSOR="" QUERY START="${3:-1970-01-01}" END="${4:-$(date -u +%Y-%m-%d)}"

  [[ "$START" == *T* ]] || START="${START}T00:00:00Z"
  [[ "$END" == *T* ]] || END="${END}T23:59:59Z"

  # shellcheck disable=SC2016
  QUERY='
    query($owner: String!, $name: String!, $endCursor: String) {
      repository(owner: $owner, name: $name) {
        forks(first: 100, after: $endCursor, orderBy: { field: CREATED_AT, direction: DESC }) {
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

  : >"$RESULTS_FORK_PATH"

  while :; do
    # CURSOR が空のときは endCursor 変数を渡さない（= null）
    if [[ -n "$CURSOR" ]]; then
      gh api graphql \
        -F owner="$OWNER" -F name="$REPO" -F endCursor="$CURSOR" \
        -f query="$QUERY" | jq '.' >"$RAW_FORK_PATH"
    else
      gh api graphql \
        -F owner="$OWNER" -F name="$REPO" \
        -f query="$QUERY" | jq '.' >"$RAW_FORK_PATH"
    fi

    # このページのノードを期間で絞って JSONL 追記
    jq -r --arg START "$START" --arg END "$END" '
      .data.repository.forks.nodes[]
      | select(.createdAt >= $START and .createdAt <= $END)
      | @json
    ' "$RAW_FORK_PATH" >>"$RESULTS_FORK_PATH"

    # 次ページ情報
    local HAS_NEXT CUR
    HAS_NEXT="$(jq -r '.data.repository.forks.pageInfo.hasNextPage' "$RAW_FORK_PATH")"
    CUR="$(jq -r '.data.repository.forks.pageInfo.endCursor' "$RAW_FORK_PATH")"
    CURSOR="$CUR"

    # 早期終了条件：このページの最古が START より古ければ以降すべて範囲外
    local OLDEST_IN_PAGE
    OLDEST_IN_PAGE="$(jq -r '
      .data.repository.forks.nodes
      | if length==0 then null else (map(.createdAt) | min) end
    ' "$RAW_FORK_PATH")"
    if [[ "$OLDEST_IN_PAGE" != "null" && "$OLDEST_IN_PAGE" < "$START" ]]; then
      break
    fi

    # まだ続きがなければ終了
    if [[ "$HAS_NEXT" != "true" || "$CURSOR" == "null" || -z "$CURSOR" ]]; then
      break
    fi
  done

  return 0
}

get_ratelimit() {
  printf '%s\n' "$(gh api graphql -f query='
  query(){
    rateLimit { remaining }
  }' --jq '.data.rateLimit.remaining')"
}

printf 'before-fork-remaining:%s\n' "$(get_ratelimit)"
get_fork "$@"
printf 'after-fork-remaining:%s\n' "$(get_ratelimit)"

jq -s '.' "$RESULTS_FORK_PATH"> ./src/designated-oss-growth/github-developer-contrib/archive/fork/results-fork.json
