#!/bin/bash

#--------------------------------------
# pull requestのレビューのコメントのリアクションを取得するファイル
#--------------------------------------

set -euo pipefail

#--------------------------------------
# プルリクエストのレビューのコメントのリアクションを取得する関数
#--------------------------------------
function get_pull_request_review_comment_reaction() {

  # データ取得前のRateLimit変数
  local before_remaining_ratelimit
  # データ取得前のRateLimitを取得
  before_remaining_ratelimit="$(get_ratelimit "before:get-pull-request-review-comment-reaction()")"

  local QUERY
  local RAW_PATH="${RESULT_GET_PR_DIR}/raw-pr-review-comment-reaction.jsonl"
  local RESULT_PATH="${RESULT_GET_PR_DIR}/result-pr-review-comment-reaction.json"

  # shellcheck disable=SC2016
  QUERY='
    query($node_id: ID!, $perPage: Int!, $endCursor: String) {
      node(id: $node_id) {
        ... on PullRequestReviewComment {
          id
          fullDatabaseId
          bodyText
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
  get_paginated_data_by_node_id "$QUERY" "$RAW_PATH" "$RESULT_PATH" "reactions" "createdAt" "$RESULT_PR_REVIEW_COMMENT_NODE_ID_PATH"

  # データ取得後のRateLimitを出力
  get_ratelimit "after:get-pull-request-review-comment-reaction()" "$before_remaining_ratelimit" "false"
}
