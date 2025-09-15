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
source "${GET_DIR}/pull-request/pr-comment.sh"
source "${GET_DIR}/pull-request/pr-comment-reaction.sh"
source "${GET_DIR}/pull-request/pr-review.sh"
source "${GET_DIR}/pull-request/pr-review-reaction.sh"
source "${GET_DIR}/pull-request/pr-review-comment.sh"
source "${GET_DIR}/pull-request/pr-review-comment-reaction.sh"
# source "${GET_DIR}/pull-request/pr-reviewer.sh"

#--------------------------------------
# 出力先のファイルを定義
#--------------------------------------
# プルリクエストのnode_idを取得するファイル
readonly RESULT_PR_NODE_ID_PATH="${RESULTS_GET_DIR}/result-pr-node-id.json"
# プルリクエストのコメントのnode_idを取得するファイル
readonly RESULT_PR_COMMENT_NODE_ID_PATH="${RESULTS_GET_DIR}/result-pr-comment.json"
# プルリクエストのレビューのnode_idを取得するファイル
readonly RESULT_PR_REVIEW_NODE_ID_PATH="${RESULTS_GET_DIR}/result-pr-review.json"
# プルリクエストのレビューのコメントのnode_idを取得するファイル
readonly RESULT_PR_REVIEW_COMMENT_NODE_ID_PATH="${RESULTS_GET_DIR}/result-pr-review-comment.json"

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

  # プルリクエストのコメントを取得
  get_pull_request_comment

  # プルリクエストのコメントのリアクションを取得
  get_pull_request_comment_reaction

  # # プルリクエストのレビューを取得
  get_pull_request_review

  # プルリクエストのレビューのリアクションを取得
  get_pull_request_review_reaction

  # # プルリクエストのレビューコメントを取得
  get_pull_request_review_comment

  # # プルリクエストのレビューコメントのリアクションを取得
  get_pull_request_review_comment_reaction

  # # プルリクエストの現在のレビュワーを取得
  # get_pull_request_reviewer

  # # プルリクエストのレビュワーのタイムラインを取得
  # get_pull_request_reviewer

  # データ取得後のRateLimitを出力
  get_ratelimit "after:get-pull-request()" "$before_remaining_ratelimit" "false"
}
