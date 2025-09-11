#!/usr/bin/env bash

#--------------------------------------
# Pull Request Review関連のデータ取得を行うファイル
#--------------------------------------

set -euo pipefail

# ページ単位の生レスポンスを置く一時JSON
readonly RAW_PULL_REQUEST_REVIEW_PER_PAGE_JSONL="./src/designated-oss-growth/github-developer-contrib/archive/pull-request-review/raw-pull-request-review.jsonl"
# 最終成果物（配列JSON）
readonly RESULTS_PULL_REQUEST_REVIEW_JSON_PATH="./src/designated-oss-growth/github-developer-contrib/archive/pull-request-review/results-pull-request-review.json"

mkdir -p "$(dirname "$RAW_PULL_REQUEST_REVIEW_PER_PAGE_JSONL")"

function usage() {
  cat <<'USAGE'
    Description:
      Get all pull request reviews in a repo (optionally filtered by date)

    Output:
      JSONL (each line = 100 pull request reviews)
      JSON array (each element = 1 pull request review)

    Example:
      pull-request-review.sh -o yoshiko-pg -r difit -s 2024-01-01 -u 2024-01-01

    Usage:
      pull-request-review.sh -o OWNER -r REPO [options]

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

function get_pull_request_review() {
  local OWNER="$1" REPO="$2" QUERY

  # shellcheck disable=SC2016
  QUERY='
    query($owner:String!, $name:String!, $endCursor:String, $since:String) {
      repository(owner:$owner, name:$name) {
        pullRequests(first:100, after:$endCursor, orderBy:{field:UPDATED_AT, direction:DESC}) {
          pageInfo { hasNextPage endCursor }
          nodes {
            number
            url
            title
            state
            isDraft
            createdAt
            closedAt
            mergedAt
            mergeStateStatus
            additions
            deletions
            changedFiles
            author { login ... on User { id } }
            authorAssociation
            assignees(first:100) { nodes { login ... on User { id } } }
            labels(first:100) { nodes { name } }
            reactionGroups { content users { totalCount } }

            comments(first:100) {
              totalCount
              nodes {
                author { login ... on User { id } }
                }
                bodyText
                reactionGroups { content users { totalCount } }
              }
            }

            reviews(first:100) {
              totalCount
              nodes {
                author { login ... on User { id } }
                state
                submittedAt
              }
            }

            reviewThreads(first:100) {
              totalCount
              nodes {
                comments(first:100) {
                  totalCount
                  nodes {
                    author { login ... on User { id } }
                    createdAt
                    bodyText
                    reactionGroups { content users { totalCount } }
                  }
                }
              }
            }

            timelineItems(first:100, itemTypes: [
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
  '

  local STATE="${3:-ALL}"
  # Paginate and emit one PR per line
  gql_paginate_nodes "$QUERY" "$OWNER" "$REPO" '.data.repository.pullRequests' '.nodes[]' |
    case "$STATE" in
    OPEN | CLOSED | MERGED) jq -c --arg s "$STATE" 'select(.state==$s)' >"$RAW_PULL_REQUEST_DIR" ;;
    *) cat ;;
    esac

  return 0
}

get_ratelimit() {
  printf '%s\n' "$(gh api graphql -f query='
  query(){
    rateLimit { remaining }
  }' --jq '.data.rateLimit.remaining')"
}

printf 'before-pull-request-review-remaining:%s\n' "$(get_ratelimit)"
get_pull_request_review "$@"
printf 'success\n'
printf 'after-pull-request-review-remaining:%s\n' "$(get_ratelimit)"
