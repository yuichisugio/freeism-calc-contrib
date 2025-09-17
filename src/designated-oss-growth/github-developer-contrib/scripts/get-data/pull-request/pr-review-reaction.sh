#!/bin/bash

#--------------------------------------
# pull requestのレビューのリアクションを取得するファイル
#--------------------------------------

set -euo pipefail

#--------------------------------------
# プルリクエストのレビューのリアクションを取得する関数
#--------------------------------------
function get_pull_request_review_reaction() {

  # データ取得前のRateLimit変数
  local before_remaining_ratelimit
  # データ取得前のRateLimitを取得
  before_remaining_ratelimit="$(get_ratelimit "before:get-pull-request-review-reaction()")"

  local QUERY
  local RAW_PATH="${RESULT_GET_PR_DIR}/raw-pr-review-reaction.jsonl"
  local RESULT_PATH="${RESULT_GET_PR_DIR}/result-pr-review-reaction.json"

  # shellcheck disable=SC2016
  QUERY='
    query($node_id: ID!, $perPage: Int!, $endCursor: String) {
      node(id: $node_id) {
        __typename
        ... on PullRequestReview {
          id
          url
          reactions(first: $perPage, after: $endCursor){
            totalCount
            pageInfo { hasNextPage endCursor }
            nodes{
              databaseId
              id
              content
              createdAt
              user { databaseId id login name url }
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
    "reactions" \
    "$RESULT_PR_REVIEW_NODE_ID_PATH" \
    "createdAt"

  # データ取得後のRateLimitを出力
  get_ratelimit \
    "after:get-pull-request-review-reaction()" \
    "$before_remaining_ratelimit" \
    "false"
}
