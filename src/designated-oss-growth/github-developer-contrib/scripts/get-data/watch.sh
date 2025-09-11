#!/bin/bash

#--------------------------------------
# watch関連のデータ取得を行うファイル
#--------------------------------------

set -euo pipefail

# 最終成果物（配列JSON）
readonly RESULTS_WATCH_JSON_PATH="./src/designated-oss-growth/github-developer-contrib/archive/watch/results-watch.json"

mkdir -p "$(dirname "$RESULTS_WATCH_JSON_PATH")"

function get_watch() {
  # 引数のデフォルト値
  local OWNER="ryoppippi"
  local REPO="ccusage"
  local QUERY

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
    *)
      printf '%s\n' "Unknown option: $1" >&2
      exit 1
      ;;
    esac
  done

  # GraphQL クエリ
  # shellcheck disable=SC2016
  QUERY='
    query($owner: String!, $name: String!, $endCursor: String) {
      repository(owner: $owner, name: $name) {
        watchers(first:100, after:$endCursor) {
          totalCount
          pageInfo { hasNextPage endCursor }
          nodes {
            login
            name
            id
            databaseId
          }
        }
      }
    }
  '

  gh api graphql \
    --paginate --slurp \
    -F owner="$OWNER" -F name="$REPO" -f query="$QUERY" |
    jq '.' >"$RESULTS_WATCH_JSON_PATH"
}

get_ratelimit() {
  printf '%s\n' "$(gh api graphql -f query='
  query { rateLimit { remaining } }
  ' --jq '.data.rateLimit.remaining')"
}

printf 'before-watch-remaining:%s\n' "$(get_ratelimit)"
get_watch "$@"
printf 'success\n'
printf 'after-watch-remaining:%s\n' "$(get_ratelimit)"
