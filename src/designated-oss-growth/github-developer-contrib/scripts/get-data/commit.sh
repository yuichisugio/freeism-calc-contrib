#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'USAGE'
    Description:
      Get all commits in a repo (optionally filtered by date) and their associated PRs
      Output: JSON array (each element = 1 commit + its PR array)
      Example:
        commit.sh -r yoshiko-pg/difit -b main --since 2024-01-01 --until 2024-01-01 --page-size 100 --prs-per-commit 20

    Usage: 
      commit.sh -r OWNER/REPO [options]

    Options:
      -r, --repo OWNER/REPO         Target repository (required)
      -b, --branch BRANCH           Target branch (default: check main and master in order, then use the first one that exists)
          --since YYYY-MM-DD[..]    Start date (GitTimestamp; 2024-01-01 or 2024-01-01T00:00:00Z)
          --until YYYY-MM-DD[..]    End date (GitTimestamp; 2024-01-01 or 2024-01-01T00:00:00Z)
          --page-size N             Number of commits to fetch per request (default: 100 / max 100)
          --prs-per-commit N        Maximum number of PRs to follow from each commit (default: 20)
      -h, --help

    Dependencies: 
      gh, jq
USAGE
}

REPO=""
BRANCH=""
SINCE=""
UNTIL=""
PAGE_SIZE=100
PRS_PER_COMMIT=20
RAW_DATA_PATH="./src/designated-oss-growth/github-developer-contrib/archive/raw-commit.json"

get_ratelimit() {
  printf '%s\n' "$(gh api graphql -f query='
  query(){
    rateLimit { remaining }
  }' --jq '.data.rateLimit.remaining')"
}

printf 'before-remaining:%s\n' "$(get_ratelimit)"

# --- 引数パース ---
while [[ $# -gt 0 ]]; do
  case "$1" in
  -r | --repo)
    REPO="$2"
    shift 2
    ;;
  -b | --branch)
    BRANCH="$2"
    shift 2
    ;;
  --since)
    SINCE="$2"
    shift 2
    ;;
  --until)
    UNTIL="$2"
    shift 2
    ;;
  --page-size)
    PAGE_SIZE="$2"
    shift 2
    ;;
  --prs-per-commit)
    PRS_PER_COMMIT="$2"
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

for tool in gh jq; do
  if ! command -v "$tool" >/dev/null; then
    printf '%s\n' "$tool not found" >&2
    exit 1
  fi
done

[[ -n "$REPO" ]] || { printf '%s\n' "-r/--repo is required" >&2; exit 1; }

OWNER="${REPO%%/*}"
NAME="${REPO#*/}"

# --- ブランチ存在チェック関数 ---
branch_exists() {
  local b="$1" ok query
  # shellcheck disable=SC2016
  query='
    query($owner:String!,$name:String!,$qualified:String!){
      repository(owner:$owner, name:$name){ ref(qualifiedName:$qualified){ name } }
    }
  '
  ok="$(gh api graphql \
    -F owner="$OWNER" -F name="$NAME" -F qualified="refs/heads/$b" \
    -f query="$query" --jq '.data.repository.ref != null' 2>/dev/null || echo false)"
  [[ "$ok" == "true" ]]
}

# --- 走査対象ブランチの決定 ---
CANDIDATES=()
if [[ -n "$BRANCH" ]]; then
  CANDIDATES+=("$BRANCH")
else
  CANDIDATES+=(main master) # デフォルトブランチ探索せず、両方をチェック
fi

FOUND=()
for b in "${CANDIDATES[@]}"; do
  if branch_exists "$b"; then
    FOUND+=("$b")
  fi
done

if [[ ${#FOUND[@]} -eq 0 ]]; then
  echo "Specified branch does not exist (when -b is not specified, main/master are checked)." >&2
  exit 1
fi

# --- GraphQL クエリ本体（共通） ---
# shellcheck disable=SC2016
GQL='
query(
  $owner: String!, $name: String!,
  $qualified: String!,
  $since: GitTimestamp, $until: GitTimestamp,
  $pageSize: Int!, $endCursor: String,
  $prsPerCommit: Int!
){
  repository(owner:$owner, name:$name){
    ref(qualifiedName:$qualified){
      name
      target {
        ... on Commit {
          history(first:$pageSize, after:$endCursor, since:$since, until:$until) {
            pageInfo { hasNextPage endCursor }
            nodes {
              oid
              abbreviatedOid
              messageHeadline
              message
              committedDate
              author { name email user { login id } }
              associatedPullRequests(first:$prsPerCommit) {
                nodes {
                  number
                  title
                  body
                  url
                  state
                  merged
                  mergedAt
                  baseRefName
                  headRefName
                  reactionGroups {
                    content
                    reactors { totalCount }
                  }
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

# --- 各ブランチを取得・整形して一時保存 ---
TMPDIR="$(mktemp -d)"
# raw を確認したい場合に最後に纏めて書き出す
RAW_ALL=()

for b in "${FOUND[@]}"; do
  QUAL="refs/heads/$b"
  RAW="$TMPDIR/raw-$b.json"

  gh api graphql \
    --paginate --slurp \
    -F owner="$OWNER" -F name="$NAME" -F qualified="$QUAL" \
    -F pageSize="$PAGE_SIZE" -F prsPerCommit="$PRS_PER_COMMIT" \
    -F since="${SINCE:-null}" -F until="${UNTIL:-null}" \
    -f query="$GQL" | jq '.' >"$RAW"

  RAW_ALL+=("$RAW")
done

# raw の結合を残しておく
jq -s '[ .[] ]' "${RAW_ALL[@]}" >"$RAW_DATA_PATH"

printf 'success\n'
printf 'after-remaining:%s\n' "$(get_ratelimit)"
