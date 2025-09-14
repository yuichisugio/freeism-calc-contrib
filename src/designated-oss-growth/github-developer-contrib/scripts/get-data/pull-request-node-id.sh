#!/bin/bash

#--------------------------------------
# pull requestのnode_idと各種フィールドのtotalCountを取得するファイル
#--------------------------------------

set -euo pipefail

#--------------------------------------
# プルリクエストのnode_idと各種フィールドのtotalCountを取得する関数
#--------------------------------------
function get_pull_request_node_id() {

  # データ取得前のRateLimit変数
  local before_remaining_ratelimit
  # データ取得前のRateLimitを取得
  before_remaining_ratelimit="$(get_ratelimit "before:get-pull-request-node-id")"

  local QUERY
  local RAW_PATH="${RAW_PR_DIR}/raw-pull-request-node-id.json"

  : >"$RAW_PATH"

  # shellcheck disable=SC2016
  QUERY='
   query($owner: String!, $name: String!, $perPage: Int!) {
      repository(owner:$owner, name:$name) {
        pullRequests(first: $perPage ,orderBy: {field : CREATED_AT,direction: ASC}){
          totalCount
          pageInfo { hasNextPage endCursor }
          nodes {
            fullDatabaseId
            id # node_id
            number
            permalink # プルリクのURL
            url # プルリクのURL
            checksUrl # チェックのURL
            additions # コード追加の行数
            deletions # コード削除の行数
            title # pull-requestもレビューする対象なのでコード行数に加算するために取得
            bodyText # プルリクの説明
            state # OPEN, CLOSED, MERGED
            publishedAt # draftからOpenになった日 or 直接Openになった日
            closedAt # REJECTEDかCLOSEDになった日
            mergedAt # マージ日
            mergedBy { login url } # マージ担当者
            reactionGroups { content reactors { totalCount } } # リアクション数
            reactions(first: 1){
              totalCount
            }
            assignedActors(first: 1){
              totalCount
            }
            labels(first: 1){
              totalCount
            }
            reviewRequests(first: 1){
              totalCount
            }
            timelineItems(last: 1, itemTypes: [LABELED_EVENT, ASSIGNED_EVENT, REVIEW_REQUESTED_EVENT]) {
              totalCount
              pageCount
              filteredCount
            }
            comments(first: 1){
              totalCount
            }
            reviews(first: 1){
              totalCount
            }
          }
        }
      }
    }
  '

  # クエリを実行。
  get_paginated_repository_data "$QUERY" "$RAW_PATH" "$RESULT_PR_NODE_ID_PATH"

  # データ取得後のRateLimitを出力
  get_ratelimit "after:get-pull-request-node-id" "$before_remaining_ratelimit" "false"
}
