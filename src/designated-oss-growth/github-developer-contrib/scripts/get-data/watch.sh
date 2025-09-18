#!/bin/bash

#--------------------------------------
# watch関連のデータ取得を行うファイル
#--------------------------------------

set -euo pipefail

#--------------------------------------
# 出力先のファイルを定義
#--------------------------------------
readonly RESULT_GET_WATCH_DIR="${OUTPUT_GET_DIR}/watch"
readonly RAW_WATCH_PATH="${RESULT_GET_WATCH_DIR}/raw-watch.json"
readonly RESULT_WATCH_PATH="${RESULT_GET_WATCH_DIR}/result-watch.json"

mkdir -p "$RESULT_GET_WATCH_DIR"

function get_watch() {

  # データ取得前のRateLimit変数
  local before_remaining_ratelimit
  # データ取得前のRateLimitを取得
  before_remaining_ratelimit="$(get_ratelimit "before:get-watch()")"

  local QUERY

  # GraphQL クエリ
  # shellcheck disable=SC2016
  QUERY='
    query($owner: String!, $name: String!, $endCursor: String) {
      repository(owner: $owner, name: $name) {
        watchers(first:50, after:$endCursor) {
          totalCount
          pageInfo { hasNextPage endCursor }
          nodes {
            login
            name
            id
            databaseId
            url
          }
        }
      }
    }
  '

  # watchはcreatedAtがないので、get_paginated_repository_data関数は使用しない
  gh api graphql \
    --header X-Github-Next-Global-ID:1 \
    --paginate --slurp \
    -F owner="$OWNER" -F name="$REPO" -f query="$QUERY" |
    jq '.' >"$RAW_WATCH_PATH"

  # データを加工して保存する
  jq '[ .[] | .data.repository.watchers.nodes[] ]' "$RAW_WATCH_PATH" >"$RESULT_WATCH_PATH"

  # データ取得後のRateLimitを出力
  get_ratelimit \
    "after:get-watch()" \
    "$before_remaining_ratelimit" \
    "false"
}
