#!/bin/bash

#--------------------------------------
# リリースのnode_idと各種フィールドのtotalCountを取得するファイル
#--------------------------------------

set -euo pipefail

#--------------------------------------
# 出力先のファイルを定義
#--------------------------------------
readonly RESULT_GET_RELEASE_DIR="${RESULTS_GET_DIR}/release"
mkdir -p "$RESULT_GET_RELEASE_DIR"
# リリースのnode_idを取得するファイル
readonly RESULT_RELEASE_NODE_ID_PATH="${RESULT_GET_RELEASE_DIR}/result-release-node-id.json"

#--------------------------------------
# リリースのnode_idと各種フィールドのtotalCountを取得する関数
#--------------------------------------
function get_release_node_id() {

  # データ取得前のRateLimit変数
  local before_remaining_ratelimit
  # データ取得前のRateLimitを取得
  before_remaining_ratelimit="$(get_ratelimit "before:get-release-node-id()")"

  local QUERY
  local RAW_PATH="${RESULT_GET_RELEASE_DIR}/raw-release-node-id.jsonl"

  : >"$RAW_PATH"

  # shellcheck disable=SC2016
  QUERY='
    query($owner: String!, $name: String!, $perPage: Int!, $endCursor: String) {
      repository(owner: $owner, name: $name) {
        releases(first: $perPage, after: $endCursor) {
          totalCount
          pageInfo { hasNextPage endCursor }
          nodes { id }
        }
      }
    }
  '

  # クエリを実行。
  get_paginated_repository_data \
    "$QUERY" \
    "$RAW_PATH" \
    "$RESULT_RELEASE_NODE_ID_PATH" \
    "releases" \
    "publishedAt"

  # データ取得後のRateLimitを出力
  get_ratelimit \
    "after:get-release-node-id()" \
    "$before_remaining_ratelimit" \
    "false"
}
