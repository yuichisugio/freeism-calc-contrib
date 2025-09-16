#!/bin/bash

#--------------------------------------
# コミットのコメントのリアクションを取得するファイル
#--------------------------------------

set -euo pipefail

#--------------------------------------
# コミットのコメントのリアクションを取得する関数
#--------------------------------------
function get_commit_comment_reaction() {

  # データ取得前のRateLimit変数
  local before_remaining_ratelimit
  # データ取得前のRateLimitを取得
  before_remaining_ratelimit="$(get_ratelimit "before:get-commit-comment-reaction()")"

  local QUERY
  local RAW_PATH="${RESULT_GET_COMMIT_DIR}/raw-commit-comment-reaction.jsonl"
  local RESULT_PATH="${RESULT_GET_COMMIT_DIR}/result-commit-comment-reaction.json"

  # shellcheck disable=SC2016
  QUERY='
    query($node_id: ID!, $perPage: Int!, $endCursor: String) {
      node(id: $node_id) {
        ... on CommitComment {
          id
          databaseId
          url
          body
          reactions(first: $perPage, after:$endCursor) {
            totalCount
            pageInfo { hasNextPage endCursor }
            nodes {
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
    "createdAt" \
    "$RESULT_COMMIT_COMMENT_PATH"

  # データ取得後のRateLimitを出力
  get_ratelimit \
    "after:get-commit-comment-reaction()" \
    "$before_remaining_ratelimit" \
    "false"
}
