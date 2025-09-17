#!/bin/bash

#--------------------------------------
# issueの現在のラベルを取得するファイル
#--------------------------------------

set -euo pipefail

#--------------------------------------
# issueの現在のラベルを取得する関数
#--------------------------------------
function get_issue_now_label() {

  # データ取得前のRateLimit変数
  local before_remaining_ratelimit
  # データ取得前のRateLimitを取得
  before_remaining_ratelimit="$(get_ratelimit "before:get-issue-now-label()")"

  local QUERY
  local RAW_PATH="${RESULT_GET_ISSUE_DIR}/raw-issue-now-label.jsonl"
  local RESULT_PATH="${RESULT_GET_ISSUE_DIR}/result-issue-now-label.json"

  # shellcheck disable=SC2016
  QUERY='
    query($node_id: ID!, $perPage: Int!, $endCursor: String) {
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
          labels(first: $perPage, after: $endCursor, orderBy: {field: CREATED_AT, direction: ASC}) {
            totalCount
            pageInfo { hasNextPage endCursor }
            nodes { 
              id
              url
              name
              description
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
    "labels" \
    "$RESULT_ISSUE_NODE_ID_PATH"

  # データ取得後のRateLimitを出力
  get_ratelimit \
    "after:get-issue-now-label()" \
    "$before_remaining_ratelimit" \
    "false"
}
