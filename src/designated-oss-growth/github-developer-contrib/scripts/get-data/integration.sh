#!/bin/bash

#--------------------------------------
# GraphQL APIのクエリのデータ取得を統合するファイル
#--------------------------------------

set -euo pipefail

#--------------------------------------
# 使用するファイルを読み込む
#--------------------------------------
source "$(dirname "$0")/repo-meta.sh"
source "$(dirname "$0")/pull-request-main.sh"
source "$(dirname "$0")/coding-commit-pullreq.sh"
source "$(dirname "$0")/star.sh"
source "$(dirname "$0")/fork.sh"
source "$(dirname "$0")/watch.sh"
source "$(dirname "$0")/pull-request-comment.sh"
source "$(dirname "$0")/sponsor.sh"
# source "$(dirname "$0")/reaction.sh"
# source "$(dirname "$0")/issue.sh"

#--------------------------------------
# 出力先のファイルを作成する
#--------------------------------------
readonly RAW_DIR="${RESULTS_DIR}/raw-data"
mkdir -p "$RAW_DIR"

#--------------------------------------
# データ取得を統合する関数
#--------------------------------------
function get_data() {

  # データ取得前のRateLimit変数
  local before_remaining_ratelimit

  # データ取得前のRateLimitを取得
  before_remaining_ratelimit="$(get_ratelimit "before-get-data")"

  # リポジトリのメタデータを取得
  get_repo_meta

  # プルリクエストのデータを取得
  get_pull_request

  # コミットのデータを取得
  get_commit

  # スターのデータを取得
  get_star

  # フォークのデータを取得
  get_fork

  # ウォッチのデータを取得
  get_watch

  # スポンサーのデータを取得
  get_sponsor

  # コメントのデータを取得
  # get_comment

  # イシューのデータを取得
  # get_issue

  # データ取得後のRateLimitを出力
  get_ratelimit "after-get-data" "$before_remaining_ratelimit"

  # 終了ステータスを成功にする
  return 0
}
