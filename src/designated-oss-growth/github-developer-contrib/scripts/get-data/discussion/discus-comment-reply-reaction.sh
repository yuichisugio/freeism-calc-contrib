#!/bin/bash

#--------------------------------------
# discussionのコメントのリプライのリアクションを取得するファイル
#--------------------------------------

set -euo pipefail

#--------------------------------------
# discussionのコメントのリプライのリアクションを取得する関数
#--------------------------------------
function get_discussion_comment_reply_reaction() {
  # データ取得前のRateLimit変数
  local before_remaining_ratelimit
  # データ取得前のRateLimitを取得
  before_remaining_ratelimit="$(get_ratelimit "before:get-discussion-comment-reply-reaction()")"

  local QUERY
  local RAW_PATH="${RESULT_GET_DISCUSSION_DIR}/raw-discus-comment-reply-reaction.jsonl"
  local RESULT_PATH="${RESULT_GET_DISCUSSION_DIR}/result-discus-comment-reply-reaction.json"

  # shellcheck disable=SC2016
  QUERY='
    query($node_id: ID!, $perPage: Int!, $endCursor: String) {
      node(id: $node_id) {
        __typename
        ... on DiscussionComment {
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
    "$RESULT_DISCUSSION_COMMENT_REPLY_NODE_ID_PATH" \
    "createdAt"

  # データ取得後のRateLimitを出力
  get_ratelimit \
    "after:get-discussion-comment-reply-reaction()" \
    "$before_remaining_ratelimit" \
    "false"
}
