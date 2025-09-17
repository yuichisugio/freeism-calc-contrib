#!/bin/bash

#--------------------------------------
# issueのラベルのタイムラインを取得するファイル
#--------------------------------------

set -euo pipefail

#--------------------------------------
# issueのラベルのタイムラインを取得する関数
#--------------------------------------
function get_issue_timeline_label() {

  # データ取得前のRateLimit変数
  local before_remaining_ratelimit
  # データ取得前のRateLimitを取得
  before_remaining_ratelimit="$(get_ratelimit "before:get-issue-timeline-label()")"

  local QUERY
  local RAW_PATH="${RESULT_GET_ISSUE_DIR}/raw-issue-timeline-label.jsonl"
  local RESULT_PATH="${RESULT_GET_ISSUE_DIR}/result-issue-timeline-label.json"

  # shellcheck disable=SC2016
  QUERY='
    query($node_id: ID!, $perPage: Int!, $endCursor: String, $since: DateTime!) {
      node(id: $node_id) {
        __typename
        ... on Issue{
          id
          fullDatabaseId
          databaseId
          number
          url
          title
          state
          publishedAt
          timelineItems(first: $perPage, after: $endCursor, itemTypes: [LABELED_EVENT], since: $since) {
            totalCount
            pageInfo { hasNextPage endCursor }
            nodes {
              __typename
              ... on LabeledEvent {
                id
                createdAt
                label { 
                  id
                  url
                  name
                  description
                }
                actor { # ラベル付けした人（実行者）
                  __typename
                  ... on User { databaseId id login name url }
                  ... on Bot { databaseId id login url }
                  ... on Mannequin { databaseId id login name url }
                  ... on Organization { databaseId id login name url }
                  ... on EnterpriseUserAccount { user { databaseId id login name url } }
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
    "$RESULT_ISSUE_NODE_ID_PATH" \
    "createdAt"

  # データ取得後のRateLimitを出力
  get_ratelimit \
    "after:get-issue-timeline-label()" \
    "$before_remaining_ratelimit" \
    "false"
}
