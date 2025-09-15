#!/bin/bash

#--------------------------------------
# pull requestのデータ取得を統合するファイル
#--------------------------------------

set -euo pipefail

#--------------------------------------
# 使用するファイルを読み込む
#--------------------------------------
source "${GET_DIR}/pull-request/pr-node-id.sh"
source "${GET_DIR}/pull-request/pr-utils.sh"
source "${GET_DIR}/pull-request/pr-reaction.sh"
source "${GET_DIR}/pull-request/pr-assigned-actors.sh"
source "${GET_DIR}/pull-request/pr-timeline-assigned.sh"
source "${GET_DIR}/pull-request/pr-label.sh"
source "${GET_DIR}/pull-request/pr-timeline-label.sh"
# source "${GET_DIR}/pull-request/pr-comment.sh"
# source "${GET_DIR}/pull-request/pr-review.sh"
# source "${GET_DIR}/pull-request/pr-review-comment.sh"
# source "${GET_DIR}/pull-request/pr-reviewer.sh"

#--------------------------------------
# 出力先のファイルを定義
#--------------------------------------
readonly RESULT_PR_NODE_ID_PATH="${RESULTS_GET_DIR}/result-pr-node-id.json"

#--------------------------------------
# プルリクエストのデータを取得する
#--------------------------------------
function get_pull_request() {

  local before_remaining_ratelimit

  # データ取得前のRateLimitを取得
  before_remaining_ratelimit="$(get_ratelimit "before:get-pull-request()")"

  # プルリクエストのnode_idと各種フィールドのtotalCountを取得
  get_pull_request_node_id

  # プルリクエストのリアクションを取得
  get_pull_request_reaction

  # プルリクエストの現在の担当者を取得
  get_pull_request_assigned_actors

  # プルリクエストの担当者のタイムラインを取得
  get_pull_request_timeline_assigned

  # プルリクエストの現在のラベルを取得
  get_pull_request_label

  # プルリクエストのラベルのタイムラインを取得
  get_pull_request_timeline_label

  # # プルリクエストのコメントを取得
  # get_pull_request_comment

  # # プルリクエストのレビューを取得
  # get_pull_request_review

  # # プルリクエストのレビューコメントを取得
  # get_pull_request_review_comment

  # # プルリクエストのレビュワーを取得
  # get_pull_request_reviewer

  # データ取得後のRateLimitを出力
  get_ratelimit "after:get-pull-request()" "$before_remaining_ratelimit" "false"
}
