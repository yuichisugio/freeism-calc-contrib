#!/bin/bash

#--------------------------------------
# pull requestの現在の担当者を取得するファイル
#--------------------------------------

set -euo pipefail

function get_pull_request_now_assigned_actors() {

  # データ取得前のRateLimit変数
  local before_remaining_ratelimit
  # データ取得前のRateLimitを取得
  before_remaining_ratelimit="$(get_ratelimit "before:get-pull-request-now-assigned-actors()")"

  local QUERY
  local RAW_PATH="${RESULT_GET_PR_DIR}/raw-pr-now-assigned-actors.jsonl"
  local RESULT_PATH="${RESULT_GET_PR_DIR}/result-pr-now-assigned-actors.json"

  # shellcheck disable=SC2016
  QUERY='
    query($node_id: ID!, $perPage: Int!, $endCursor: String) {
      node(id: $node_id) {
        ... on PullRequest{
          id
          number
          url
          assignedActors(first: $perPage, after: $endCursor){
            totalCount
            pageInfo { hasNextPage endCursor }
            nodes {
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
  '

  # クエリを実行。node_id単位でページネーションしながら取得
  get_paginated_data_by_node_id "$QUERY" "$RAW_PATH" "$RESULT_PATH" "assignedActors"

  # データ取得後のRateLimitを出力
  get_ratelimit "after:get-pull-request-now-assigned-actors()" "$before_remaining_ratelimit" "false"
}
