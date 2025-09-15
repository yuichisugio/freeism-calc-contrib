#!/bin/bash

#--------------------------------------
# pull requestの現在のラベルを取得するファイル
#--------------------------------------

set -euo pipefail

function get_pull_request_now_label() {

  # データ取得前のRateLimit変数
  local before_remaining_ratelimit
  # データ取得前のRateLimitを取得
  before_remaining_ratelimit="$(get_ratelimit "before:get-pull-request-now-label()")"

  local QUERY
  local RAW_PATH="${RESULT_GET_PR_DIR}/raw-pr-now-label.jsonl"
  local RESULT_PATH="${RESULT_GET_PR_DIR}/result-pr-now-label.json"

  # shellcheck disable=SC2016
  QUERY='
    query($node_id: ID!, $perPage: Int!, $endCursor: String) {
      node(id: $node_id) {
        ... on PullRequest{
          id
          number
          url
          labels(first: $perPage, after: $endCursor) {
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
  get_paginated_data_by_node_id "$QUERY" "$RAW_PATH" "$RESULT_PATH" "labels"

  # データ取得後のRateLimitを出力
  get_ratelimit "after:get-pull-request-now-label()" "$before_remaining_ratelimit" "false"
}
