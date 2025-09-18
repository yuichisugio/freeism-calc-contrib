#!/bin/bash

#--------------------------------------
# データ取得を統合するファイル
#--------------------------------------

set -euo pipefail

# --------------------------------------
# 出力先のディレクトリを作成する
# --------------------------------------
readonly OUTPUT_GET_DIR="${OUTPUT_DIR}/get-data"
mkdir -p "$OUTPUT_GET_DIR"

#--------------------------------------
# 使用するファイルを読み込む
#--------------------------------------
readonly GET_DIR="${SCRIPT_DIR}/scripts/get-data"
source "${GET_DIR}/get-data-utils.sh"
# source "${GET_DIR}/issue/issue-main.sh"
# source "${GET_DIR}/discussion/discus-main.sh"
# source "${GET_DIR}/commit/commit-main.sh"
# source "${GET_DIR}/pull-request/pr-main.sh"
# source "${GET_DIR}/release/release-main.sh"
# source "${GET_DIR}/star.sh"
# source "${GET_DIR}/fork.sh"
# source "${GET_DIR}/watch.sh"
source "${GET_DIR}/sponsor.sh"
# source "${GET_DIR}/repo-meta.sh"

#--------------------------------------
# データ取得を統合する関数
# アルファベット順でデータ取得する。引数で指定したデータのみ実行する場合に指定しやすいように順番に並べる。
#--------------------------------------
function get_data() {

  # データ取得前のRateLimit変数
  local before_remaining_ratelimit

  # データ取得前のRateLimitを取得
  before_remaining_ratelimit="$(get_ratelimit "before:get-data()")"

  # コミットのデータを取得
  # get_commit

  # ディスカッションのデータを取得
  # get_discussion

  # フォークのデータを取得
  # get_fork

  # イシューのデータを取得
  # get_issue

  # プルリクエストのデータを取得
  # get_pull_request

  # リリースのデータを取得
  # get_release

  # リポジトリのメタデータを取得
  # get_repo_meta

  # スポンサーのデータを取得
  get_sponsor

  # スターのデータを取得
  # get_star

  # ウォッチのデータを取得
  # get_watch

  # データ取得後のRateLimitを出力
  get_ratelimit "after:get-data()" "$before_remaining_ratelimit" "false"
}
