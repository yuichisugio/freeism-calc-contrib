#!/usr/bin/env bash

#--------------------------------------
# commit関連のデータ取得を行うファイル
#--------------------------------------

set -euo pipefail

# ページ単位の生レスポンスを置く一時JSON
readonly RAW_COMMIT_PER_PAGE_JSONL="./src/designated-oss-growth/github-developer-contrib/archive/coding-commit-pullreq/raw-commit-per-page.jsonl"
# 最終成果物（配列JSON）
readonly RESULTS_COMMIT_JSON_PATH="./src/designated-oss-growth/github-developer-contrib/archive/coding-commit-pullreq/results-commit.json"

mkdir -p "$(dirname "$RAW_COMMIT_PER_PAGE_JSONL")"

function usage() {
  cat <<'USAGE'
    Description:
      Get all commits in a repo (optionally filtered by date) and their associated PRs

    Output:
      JSONL (each line = 100 commits + its PR array)
      JSON array (each element = 100 commits + its PR array)

    Example:
      coding-commit-pullreq.sh -o yoshiko-pg -r difit -s 2024-01-01 -u 2024-01-01

    Usage:
      coding-commit-pullreq.sh -o OWNER -r REPO [options]

    Options:
      -o, --owner OWNER         Target owner (required)
      -r, --repo REPO         Target repository (required)
      -s, --since YYYY-MM-DD[..]    Start date (GitTimestamp; 2024-01-01 or 2024-01-01T00:00:00Z)
      -u, --until YYYY-MM-DD[..]    End date (GitTimestamp; 2024-01-01 or 2024-01-01T00:00:00Z)
      -h, --help

    Dependencies:
      gh, jq
USAGE
}

# --- ブランチ存在チェック関数 ---
function branch_exists() {
  local b="$1" ok query

  # shellcheck disable=SC2016
  query='
      query($owner:String!,$name:String!,$qualified:String!){
        repository(owner:$owner, name:$name){ ref(qualifiedName:$qualified){ name } }
      }
    '

  # ブランチが存在するかどうかをチェック
  ok="$(gh api graphql \
    -F owner="$OWNER" -F name="$REPO" -F qualified="refs/heads/$b" \
    -f query="$query" --jq '.data.repository.ref != null' 2>/dev/null || echo false)"
  [[ "$ok" == "true" ]]
}

function get_commit() {
  local OWNER="ryoppippi"
  local REPO="ccusage"
  local SINCE="1970-01-01T00:00:00Z"
  local END
  END="$(date -u +%Y-%m-%dT23:59:59Z)"

  # --- 引数パース ---
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
    -s | --start | --since)
      SINCE="$2"
      shift 2
      ;;
    -e | --end | -u | --until)
      END="$2"
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      printf '%s\n' "Unknown option: $1" >&2
      usage
      exit 1
      ;;
    esac
  done

  # ISO 8601 に正規化（文字列比較で時系列順に一致する）
  [[ "$SINCE" == *T* ]] || SINCE="${SINCE}T00:00:00Z"
  [[ "$END" == *T* ]] || END="${END}T23:59:59Z"

  for tool in gh jq; do
    if ! command -v "$tool" >/dev/null; then
      printf '%s\n' "$tool not found" >&2
      exit 1
    fi
  done

  FOUND=()
  for b in main master; do
    if branch_exists "$b"; then
      FOUND+=("$b")
    fi
  done

  if [[ ${#FOUND[@]} -eq 0 ]]; then
    printf '%s\n' "master/main branch does not exist" >&2
    exit 1
  fi

  # 同じPATHに実行する場合に、前回の内容をファイルを空にする
  : >"$RAW_COMMIT_PER_PAGE_JSONL"

  # --- GraphQL クエリ本体（共通） ---
  # shellcheck disable=SC2016
  GQL='
  query(
    $owner: String!,
    $name: String!,
    $qualified: String!,
    $since: GitTimestamp,
    $until: GitTimestamp,
    $endCursor: String
  ){
    repository(owner:$owner, name:$name){
      ref(qualifiedName:$qualified){
        name
        target {
          ... on Commit {
            history(first:100, after:$endCursor, since:$since, until:$until) {
              pageInfo { hasNextPage endCursor }
              totalCount
              nodes {
                oid
                authoredDate
                message
                additions
                deletions
                authoredByCommitter
                authors(first:5) {
                  totalCount
                  nodes {
                    name
                    user { login databaseId }
                  }
                }
                url
                associatedPullRequests(first:3) {
                  totalCount
                  nodes {
                    author { login url }
                    baseRefName
                    fullDatabaseId
                    url
                    title
                    bodyText
                    reactionGroups{content reactors { totalCount }}
                  }
                }
              }
            }
          }
        }
      }
    }
  }
  '

  # main/master それぞれのブランチのコミットを取得
  for b in "${FOUND[@]}"; do
    QUAL="refs/heads/$b"

    gh api graphql \
      --paginate --slurp \
      -F owner="$OWNER" \
      -F name="$REPO" \
      -F qualified="$QUAL" \
      -F since="$SINCE" \
      -F until="$END" \
      -f query="$GQL" |
      jq '.' >>"$RAW_COMMIT_PER_PAGE_JSONL"

  done

  # raw-data を結合
  jq -s '[ .[] ]' "${RAW_COMMIT_PER_PAGE_JSONL}" >"$RESULTS_COMMIT_JSON_PATH"
}

get_ratelimit() {
  printf '%s\n' "$(gh api graphql -f query='
  query(){
    rateLimit { remaining }
  }' --jq '.data.rateLimit.remaining')"
}

printf 'before-commit-remaining:%s\n' "$(get_ratelimit)"
get_commit "$@"
printf 'success\n'
printf 'after-commit-remaining:%s\n' "$(get_ratelimit)"
