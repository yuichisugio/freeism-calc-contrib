#!/bin/bash

#--------------------------------------
# pull requestのレビュワーのタイムラインを取得するファイル
#--------------------------------------

set -euo pipefail

#--------------------------------------
# pull requestのレビュワーのタイムラインを取得する関数
#--------------------------------------
function get_pull_request_timeline_reviewer() {

  # データ取得前のRateLimit変数
  local before_remaining_ratelimit
  # データ取得前のRateLimitを取得
  before_remaining_ratelimit="$(get_ratelimit "before:get-pull-request-timeline-reviewer()")"

  local QUERY
  local RAW_PATH="${RESULT_GET_PR_DIR}/raw-pr-timeline-reviewer.jsonl"
  local RESULT_PATH="${RESULT_GET_PR_DIR}/result-pr-timeline-reviewer.json"

  # shellcheck disable=SC2016
  QUERY='
    query($node_id: ID!, $perPage: Int!, $since: DateTime!, $endCursor: String) {
      node(id: $node_id) {
        __typename
        ... on PullRequest{
          id
          number
          url
          timelineItems(first: $perPage, itemTypes: [REVIEW_REQUESTED_EVENT], since: $since, after: $endCursor) {
            totalCount
            pageInfo { hasNextPage endCursor }
            nodes {
              __typename
              ... on ReviewRequestedEvent {
                id
                createdAt
                actor { # アサインした人（実行者）
                  __typename
                  ... on User { databaseId id login name url }
                  ... on Bot { databaseId id login url }
                  ... on Mannequin { databaseId id login name url }
                  ... on Organization { databaseId id login name url }
                  ... on EnterpriseUserAccount { user { databaseId id login name url } }
                }
                requestedReviewer {
                  __typename
                  ... on User { databaseId id login name url }
                  ... on Bot { databaseId id login url }
                  ... on Mannequin { databaseId id login name url }
                  ... on Team { databaseId id name url }
                } 
              }
            }
          }
        }
      }
    }
  '

  # クエリを実行。node_id単位でページネーションしながら取得
  get_paginated_data_by_node_id \
    "$QUERY" \
    "$RAW_PATH" \
    "$RESULT_PATH" \
    "timelineItems" \
    "$RESULT_PR_NODE_ID_PATH" \
    "createdAt"

  # データ取得後のRateLimitを出力
  get_ratelimit \
    "after:get-pull-request-timeline-reviewer()" \
    "$before_remaining_ratelimit" \
    "false"
}
