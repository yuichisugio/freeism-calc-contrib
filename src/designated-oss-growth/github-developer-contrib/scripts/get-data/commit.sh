#!/usr/bin/env bash

#--------------------------------------
# commit関連のデータ取得を行うファイル
#--------------------------------------

set -euo pipefail

usage() {
  cat <<'USAGE'
    Description:
      Get all commits in a repo (optionally filtered by date) and their associated PRs

    Output:
      JSONL (each line = 1 commit + its PR array)
      JSON array (each element = 1 commit + its PR array)

    Example:
      commit.sh -r yoshiko-pg/difit -s 2024-01-01 -u 2024-01-01 -p 100 -pe 20

    Usage:
      commit.sh -r OWNER/REPO [options]

    Options:
      -r, --repo OWNER/REPO         Target repository (required)
      -s, --since YYYY-MM-DD[..]    Start date (GitTimestamp; 2024-01-01 or 2024-01-01T00:00:00Z)
      -u, --until YYYY-MM-DD[..]    End date (GitTimestamp; 2024-01-01 or 2024-01-01T00:00:00Z)
      -p, --page-size N             Number of commits to fetch per request (default: 100 / max 100)
      -pe, --prs-per-commit N        Maximum number of PRs to follow from each commit (default: 20)
      -h, --help

    Dependencies:
      gh, jq
USAGE
}

REPO=""
SINCE=""
UNTIL=""
PAGE_SIZE=100
PRS_PER_COMMIT=100
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
  -s | --since)
    SINCE="$2"
    shift 2
    ;;
  -u | --until)
    UNTIL="$2"
    shift 2
    ;;
  -p | --page-size)
    PAGE_SIZE="$2"
    shift 2
    ;;
  -pe | --prs-per-commit)
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

[[ -n "$REPO" ]] || {
  printf '%s\n' "-r/--repo is required" >&2
  exit 1
}

OWNER="${REPO%%/*}"
NAME="${REPO#*/}"

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
    -F owner="$OWNER" -F name="$NAME" -F qualified="refs/heads/$b" \
    -f query="$query" --jq '.data.repository.ref != null' 2>/dev/null || echo false)"

  # 返す値をtrue/falseにする
  [[ "$ok" == "true" ]]
}

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

# --- GraphQL クエリ本体（共通） ---
# shellcheck disable=SC2016
GQL='
query(
  $owner: String!,
  $name: String!,
  $qualified: String!,
  $pageSize: Int!,
  $prsPerCommit: Int!,
  $since: GitTimestamp,
  $until: GitTimestamp,
  $endCursor: String
){
  repository(owner:$owner, name:$name){
    ref(qualifiedName:$qualified){
      name
      target {
        ... on Commit {
          history(first:$pageSize, after:$endCursor, since:$since, until:$until) {
            pageInfo { hasNextPage endCursor }
            nodes {
              id
              committedDate
              messageHeadline
              messageBody
              message
              additions
              deletions
              authoredByCommitter
              author { name email user { login id } }
              authors(first:2) { nodes { name email user { login id } } }
              associatedPullRequests(first:$prsPerCommit) {
                nodes {
                  assignedActors(first: 2) { totalCount nodes { ... on User { login id } } }
                  assignees(first: 2) { nodes { login ... on User { id } } }
                  author { login avatarUrl resourcePath url }
                  authorAssociation
                  autoMergeRequest{authorEmail commitHeadline commitBody enabledAt enabledBy{login} mergeMethod }
                  baseRef{name }
                  baseRefName
                  baseRefOid
                  baseRepository { nameWithOwner id }
                  body
                  bodyHTML
                  bodyText
                  canBeRebased
                  changedFiles
                  checksResourcePath
                  checksUrl
                  closed
                  closedAt
                  closingIssuesReferences(first:2) { totalCount nodes { author { login ... on User { id } } number title state } }
                  comments(first:2) { totalCount nodes { author { login } createdAt bodyText reactionGroups { content users { totalCount } } } }
                  createdAt
                  createdViaEmail
                  deletions
                  editor{login avatarUrl resourcePath url}
                  files(first: 1) { totalCount }
                  fullDatabaseId
                  headRef{name }
                  headRefName
                  headRefOid
                  headRepository { nameWithOwner id }
                  headRepositoryOwner { login avatarUrl resourcePath url }
                  hovercard { contexts { message octicon } }
                  id
                  includesCreatedEdit
                  isCrossRepository
                  isDraft
                  isInMergeQueue
                  isMergeQueueEnabled
                  isReadByViewer
                  lastEditedAt
                  latestOpinionatedReviews(first: 1) { nodes { id } }
                  latestReviews(first: 1) { nodes { id } }
                  locked
                  maintainerCanModify
                  labels(first:2) { nodes { name } }
                  mergeQueue{ id }
                  mergeQueueEntry{ id }
                  mergeStateStatus
                  mergeable
                  merged
                  mergedAt
                  mergedBy { login }
                  milestone{ id title number }
                  number
                  participants(first: 1) { totalCount }
                  permalink
                  potentialMergeCommit { oid }
                  projectItems(first: 1) { totalCount }
                  publishedAt
                  reactionGroups{content reactors { totalCount }}
                  reactions(first:2){nodes{content createdAt}}
                  repository{nameWithOwner}
                  resourcePath
                  revertResourcePath
                  revertUrl
                  reviewDecision
                  reviewRequests(first:2){ nodes { requestedReviewer { __typename ... on User { login id } ... on Team { name id } } } }
                  reviewThreads(first:2){
                    nodes {
                      comments(first:2){ nodes {
                        author { login ... on User { id } }
                        createdAt
                        bodyText
                        reactionGroups { content reactors { totalCount } }
                        }
                      }
                    }
                  }
                  reviews{nodes{author{login ... on User{id}} state submittedAt}}
                  state
                  title
                  titleHTML
                  totalCommentsCount
                  updatedAt
                  url
                  userContentEdits{totalCount}
                  viewerCanUpdate
                  viewerCanReact
                  viewerCanSubscribe
                  viewerCanReopen
                  viewerCanClose
                  viewerCanDeleteHeadRef
                  viewerCanMergeAsAdmin
                  statusCheckRollup{state contexts(first: 1) { totalCount }}
                  timelineItems(first:2, itemTypes:[
                    LABELED_EVENT,
                    UNLABELED_EVENT,
                    ASSIGNED_EVENT,
                    UNASSIGNED_EVENT,
                    REVIEW_REQUESTED_EVENT,
                    READY_FOR_REVIEW_EVENT,
                    MERGED_EVENT,
                    CLOSED_EVENT
                  ]) {
                    totalCount
                    pageInfo { hasNextPage endCursor }
                    nodes {
                      __typename
                      ... on LabeledEvent { createdAt label { name } actor { login } }
                      ... on UnlabeledEvent { createdAt label { name } actor { login } }
                      ... on AssignedEvent { createdAt assignee { __typename ... on User { login id } } actor { login } }
                      ... on UnassignedEvent { createdAt assignee { __typename ... on User { login id } } actor { login } }
                      ... on ReviewRequestedEvent { createdAt requestedReviewer { __typename ... on User { login id } ... on Team { name id } } actor { login } }
                      ... on ReadyForReviewEvent { createdAt actor { login } }
                      ... on MergedEvent { createdAt mergeRefName }
                      ... on ClosedEvent { createdAt }
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
