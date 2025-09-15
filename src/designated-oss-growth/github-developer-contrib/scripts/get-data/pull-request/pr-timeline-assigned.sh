#!/bin/bash

#--------------------------------------
# pull requestの担当者取得を統合するファイル
#--------------------------------------

set -euo pipefail

function get_pull_request_timeline_assigned() {

  # データ取得前のRateLimit変数
  local before_remaining_ratelimit
  # データ取得前のRateLimitを取得
  before_remaining_ratelimit="$(get_ratelimit "before:get-pull-request-timeline-assigned()")"

  local QUERY
  local RAW_PATH="${RESULTS_GET_DIR}/raw-pr-timeline-assigned.jsonl"
  local RESULT_PATH="${RESULTS_GET_DIR}/result-pr-timeline-assigned.json"

  # shellcheck disable=SC2016
  QUERY='
    query($node_id: ID!, $perPage: Int!, $endCursor: String, $since: DateTime!) {
      node(id: $node_id) {
        ... on PullRequest{
          id
          number
          url
          timelineItems(first: $perPage, after: $endCursor, itemTypes: [ASSIGNED_EVENT], since: $since) {
            totalCount
            pageInfo { hasNextPage endCursor }
            nodes {
              __typename
              ... on AssignedEvent {
                createdAt
                actor { # アサインした人（実行者）
                  __typename
                  ... on User { databaseId id login name url }
                  ... on Bot { databaseId id login url }
                  ... on Mannequin { databaseId id login name url }
                  ... on Organization { databaseId id login name url }
                  ... on EnterpriseUserAccount { user { databaseId id login name url } }
                }
                assignee { # アサインされた側（User/Mannequin 等の Union）
                  __typename
                  ... on User { databaseId id login name url }
                  ... on Bot { databaseId id login url }
                  ... on Mannequin { databaseId id login name url }
                  ... on Organization { databaseId id login name url }
                }
              }
            }
          }
        }
      }
    }
  '

  # クエリを実行。node_id単位でページネーションしながら取得
  get_paginated_data_by_node_id "$QUERY" "$RAW_PATH" "$RESULT_PATH" "timelineItems" "createdAt"

  # データ取得後のRateLimitを出力
  get_ratelimit "after:get-pull-request-timeline-assigned()" "$before_remaining_ratelimit" "false"
}
