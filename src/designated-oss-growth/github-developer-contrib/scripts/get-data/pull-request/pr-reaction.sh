#!/bin/bash

#--------------------------------------
# pull requestのリアクションを取得するファイル
#--------------------------------------

set -euo pipefail

#--------------------------------------
# プルリクエストのリアクションを取得する関数
#--------------------------------------
function get_pull_request_reaction() {

  # データ取得前のRateLimit変数
  local before_remaining_ratelimit
  # データ取得前のRateLimitを取得
  before_remaining_ratelimit="$(get_ratelimit "before:get-pull-request-reaction()")"

  local QUERY
  local RAW_PATH="${RESULTS_GET_DIR}/raw-pr-reaction.jsonl"
  local RESULT_PATH="${RESULTS_GET_DIR}/result-pr-reaction.json"

  # shellcheck disable=SC2016
  QUERY='
    query($node_id: ID!, $perPage: Int!, $endCursor: String) {
      node(id: $node_id) {
        ... on PullRequest{
          reactions(first: $perPage, after: $endCursor){
            totalCount
            pageInfo { hasNextPage endCursor }
            nodes { databaseId id content createdAt user { databaseId id login name url } }
          }
        }
      }
    }
  '

  # クエリを実行。
  get_paginated_repository_data "$QUERY" "$RAW_PATH" "$RESULT_PATH" "reactions" "createdAt"

  # データ取得後のRateLimitを出力
  get_ratelimit "after:get-pull-request-reaction()" "$before_remaining_ratelimit" "false"
}
