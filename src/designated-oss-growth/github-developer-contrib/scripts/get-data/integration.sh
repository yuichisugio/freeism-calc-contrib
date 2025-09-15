#!/bin/bash

#--------------------------------------
# GraphQL APIのクエリのデータ取得を統合するファイル
#--------------------------------------

set -euo pipefail

# --------------------------------------
# 出力先のファイルを作成する
# --------------------------------------
readonly RESULTS_GET_DIR="${RESULTS_DIR}/get-data"
mkdir -p "$RESULTS_GET_DIR"

#--------------------------------------
# 使用するファイルを読み込む
#--------------------------------------
readonly GET_DIR="${SCRIPT_DIR}/scripts/get-data"
# source "${GET_DIR}/repo-meta.sh"
# source "${GET_DIR}/pull-request/pr-main.sh"
# source "${GET_DIR}/star.sh"
source "${GET_DIR}/fork.sh"
# source "${GET_DIR}/watch.sh"
# source "${GET_DIR}/sponsor.sh"
# source "${GET_DIR}/coding-commit-pullreq.sh"
# source "${GET_DIR}/reaction.sh"
# source "${GET_DIR}/issue.sh"

#--------------------------------------
# データ取得を統合する関数
#--------------------------------------
function get_data() {

  # データ取得前のRateLimit変数
  local before_remaining_ratelimit

  # データ取得前のRateLimitを取得
  before_remaining_ratelimit="$(get_ratelimit "before:get-data()")"

  # リポジトリのメタデータを取得
  # get_repo_meta

  # プルリクエストのデータを取得
  # get_pull_request

  # スターのデータを取得
  # get_star

  # フォークのデータを取得
  get_fork

  # ウォッチのデータを取得
  # get_watch

  # スポンサーのデータを取得
  # get_sponsor

  # コミットのデータを取得
  # get_commit

  # コメントのデータを取得
  # get_comment

  # イシューのデータを取得
  # get_issue

  # データ取得後のRateLimitを出力
  get_ratelimit "after:get-data()" "$before_remaining_ratelimit" "false"
}
