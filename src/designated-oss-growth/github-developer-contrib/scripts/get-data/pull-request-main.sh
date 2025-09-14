#!/bin/bash

#--------------------------------------
# pull requestのデータ取得を統合するファイル
#--------------------------------------

set -euo pipefail

#--------------------------------------
# 使用するファイルを読み込む
#--------------------------------------
source "$(dirname "$0")/pull-request-node-id.sh"
source "$(dirname "$0")/pull-request-reaction.sh"
source "$(dirname "$0")/pull-request-comment.sh"
source "$(dirname "$0")/pull-request-review.sh"
source "$(dirname "$0")/pull-request-review-comment.sh"
source "$(dirname "$0")/pull-request-label.sh"
source "$(dirname "$0")/pull-request-assignee.sh"
source "$(dirname "$0")/pull-request-reviewer.sh"

#--------------------------------------
# 出力先のファイルを作成する
#--------------------------------------
readonly GET_PR_DIR="${GET_DIR}/pull-request"
readonly RESULT_PR_NODE_ID_PATH="${GET_PR_DIR}/result-pull-request-node-id.json"
mkdir -p "$GET_PR_DIR"

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

  # プルリクエストのコメントを取得
  get_pull_request_comment

  # プルリクエストのレビューを取得
  get_pull_request_review

  # プルリクエストのレビューコメントを取得
  get_pull_request_review_comment

  # プルリクエストのラベルを取得
  get_pull_request_label

  # プルリクエストの担当者を取得
  get_pull_request_assignee

  # プルリクエストのレビュワーを取得
  get_pull_request_reviewer

  # データ取得後のRateLimitを出力
  get_ratelimit "after:get-pull-request()" "$before_remaining_ratelimit"
}
