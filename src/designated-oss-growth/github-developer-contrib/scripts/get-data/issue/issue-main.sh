#!/bin/bash

#--------------------------------------
# issueのデータ取得を統合するファイル
#--------------------------------------

set -euo pipefail

#--------------------------------------
# 出力先のファイルを定義
#--------------------------------------
readonly RESULT_GET_ISSUE_DIR="${OUTPUT_GET_DIR}/issue"
mkdir -p "$RESULT_GET_ISSUE_DIR"
# issueのnode_idを取得するファイル
readonly RESULT_ISSUE_NODE_ID_PATH="${RESULT_GET_ISSUE_DIR}/result-issue-node-id.json"
# issueのコメントのnode_idを取得するファイル
readonly RESULT_ISSUE_COMMENT_NODE_ID_PATH="${RESULT_GET_ISSUE_DIR}/result-issue-comment.json"

#--------------------------------------
# 使用するファイルを読み込む
#--------------------------------------
source "${GET_DIR}/issue/issue-node-id.sh"
source "${GET_DIR}/issue/issue-now-assigned-actors.sh"
source "${GET_DIR}/issue/issue-now-label.sh"
source "${GET_DIR}/issue/issue-timeline-label.sh"
source "${GET_DIR}/issue/issue-comment.sh"
source "${GET_DIR}/issue/issue-comment-reaction.sh"
source "${GET_DIR}/issue/issue-reaction.sh"

#--------------------------------------
# データ取得を統合する関数
#--------------------------------------
function get_issue() {

  local before_remaining_ratelimit

  # データ取得前のRateLimitを取得
  before_remaining_ratelimit="$(get_ratelimit "before:get-issue()")"

  # issueのnode_idと各種フィールドのtotalCountを取得
  get_issue_node_id

  # issueの現在の担当者を取得
  get_issue_now_assigned_actors

  # issueの現在のラベルを取得
  get_issue_now_label

  # issueの担当者のタイムラインを取得
  get_issue_timeline_label

  # issueのコメントを取得
  get_issue_comment

  # issueのコメントのリアクションを取得
  get_issue_comment_reaction

  # issueのリアクションを取得
  get_issue_reaction

  # データ取得後のRateLimitを出力
  get_ratelimit \
    "after:get-issue()" \
    "$before_remaining_ratelimit" \
    "false"
}
