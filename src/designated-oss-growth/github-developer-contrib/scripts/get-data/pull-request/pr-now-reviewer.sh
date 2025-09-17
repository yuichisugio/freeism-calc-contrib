#!/bin/bash

#--------------------------------------
# pull requestの現在のレビュワーを取得するファイル
#--------------------------------------

set -euo pipefail

function get_pull_request_now_reviewer() {

  # データ取得前のRateLimit変数
  local before_remaining_ratelimit
  # データ取得前のRateLimitを取得
  before_remaining_ratelimit="$(get_ratelimit "before:get-pull-request-now-reviewer()")"

  local QUERY
  local RAW_PATH="${RESULT_GET_PR_DIR}/raw-pr-now-reviewer.jsonl"
  local RESULT_PATH="${RESULT_GET_PR_DIR}/result-pr-now-reviewer.json"

  # shellcheck disable=SC2016
  QUERY='
    query($node_id: ID!, $perPage: Int!, $endCursor: String) {
      node(id: $node_id) {
        __typename
        ... on PullRequest{
          id
          number
          url
          reviewRequests(first: $perPage, after: $endCursor){
            totalCount
            pageInfo { hasNextPage endCursor }
            nodes {
              databaseId
              id
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
  '

  # クエリを実行。node_id単位でページネーションしながら取得
  get_paginated_data_by_node_id \
    "$QUERY" \
    "$RAW_PATH" \
    "$RESULT_PATH" \
    "reviewRequests" \
    "$RESULT_PR_NODE_ID_PATH"

  # データ取得後のRateLimitを出力
  get_ratelimit \
    "after:get-pull-request-now-reviewer()" \
    "$before_remaining_ratelimit" \
    "false"
}
