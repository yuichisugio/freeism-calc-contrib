#!/usr/bin/env bash

#--------------------------------------
# Pull Request Reviewerの情報を取得する
#--------------------------------------

set -euo pipefail

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
