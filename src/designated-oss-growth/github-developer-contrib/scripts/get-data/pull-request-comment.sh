#!/bin/bash

#--------------------------------------
# pull request関連のデータ取得を行うファイル
#--------------------------------------

set -euo pipefail

cd "$(cd "$(dirname -- "$0")" && pwd -P)"

function get_pull_request() {
  local owner="$1" repo="$2" QUERY

  # shellcheck disable=SC2016
  QUERY='
    query($owner:String!, $name:String!, $cursor:String) {
      repository(owner:$owner, name:$name) {
        pullRequests(first: 50, after: $cursor, orderBy:{field:CREATED_AT, direction:ASC}, states:[OPEN, CLOSED, MERGED]) {
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
            assignees(first:50) { nodes { login ... on User { id } } }
            labels(first:50) { nodes { name } }
            reactionGroups { content users { totalCount } }

            comments(first:50) {
              totalCount
              nodes {
                author { login ... on User { id } }
                createdAt
                bodyText
                reactionGroups { content users { totalCount } }
              }
            }

            reviews(first:50) {
              totalCount
              nodes {
                author { login ... on User { id } }
                state
                submittedAt
              }
            }

            reviewThreads(first:50) {
              totalCount
              nodes {
                comments(first:50) {
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

            timelineItems(first:50, itemTypes: [
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
  gql_paginate_nodes "$QUERY" "$owner" "$repo" '.data.repository.pullRequests' '.nodes[]' |
    case "$STATE" in
    OPEN | CLOSED | MERGED) jq -c --arg s "$STATE" 'select(.state==$s)' >"$RAW_PULL_REQUEST_DIR" ;;
    *) cat ;;
    esac

  return 0
}

get_pull_request "$@"
