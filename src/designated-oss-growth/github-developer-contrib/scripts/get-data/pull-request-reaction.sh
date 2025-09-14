#!/bin/bash

#--------------------------------------
# pull requestのリアクションを取得するファイル
#--------------------------------------

set -euo pipefail

#--------------------------------------
# 出力先のファイルのPATHを定義する
#--------------------------------------
readonly RAW_PR_REACTION_PATH="${GET_PR_DIR}/raw-pr-reaction.json"
readonly RESULT_PR_REACTION_PATH="${GET_PR_DIR}/result-pr-reaction.json"

#--------------------------------------
# プルリクエストのリアクションを取得する関数
#--------------------------------------
function get_pull_request_reaction() {

  # データ取得前のRateLimit変数
  local before_remaining_ratelimit
  # データ取得前のRateLimitを取得
  before_remaining_ratelimit="$(get_ratelimit "before:get-pull-request-reaction")"

  local QUERY
  local RAW_PATH="${RAW_PULL_REQUEST_DIR}/raw-pull-request-reaction.json"
  local RESULTS_PATH="${RAW_PULL_REQUEST_DIR}/results-pull-request-reaction.json"

  : >"$RAW_PATH"
  : >"$RESULTS_PATH"

  if [[ -n "$(jq -r '.data.repository.pullRequests.nodes[] | .reactionGroups' "$RAW_PATH")" ]]; then
    jq -r '.data.repository.pullRequests.nodes[] | .reactionGroups' "$RAW_PATH"
  else
    jq -r '.data.repository.pullRequests.nodes[] | .reactionGroups' "$RAW_PATH"
  fi

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
  get_paginated_repository_data "$QUERY" "$RAW_PATH" "$RESULTS_PATH"

  # データ取得後のRateLimitを出力
  get_ratelimit "after:get-pull-request-reaction" "$before_remaining_ratelimit" "false"
}
