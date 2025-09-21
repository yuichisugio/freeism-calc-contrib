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
source "${GET_DIR}/star.sh"
source "${GET_DIR}/fork.sh"
source "${GET_DIR}/watch.sh"
source "${GET_DIR}/sponsor.sh"
source "${GET_DIR}/repo-meta.sh"

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
  if should_run "commit" "$@"; then get_commit; fi

  # ディスカッションのデータを取得
  if should_run "discussion" "$@"; then get_discussion; fi

  # フォークのデータを取得
  if should_run "fork" "$@"; then get_fork; fi

  # イシューのデータを取得
  if should_run "issue" "$@"; then get_issue; fi

  # プルリクエストのデータを取得
  if should_run "pull-request" "$@"; then get_pull_request; fi

  # リリースのデータを取得
  if should_run "release" "$@"; then get_release; fi

  # リポジトリのメタデータを取得
  if should_run "repo-meta" "$@"; then get_repo_meta; fi

  # スポンサーのデータを取得
  if should_run "sponsor" "$@"; then get_sponsor; fi

  # スターのデータを取得
  if should_run "star" "$@"; then get_star; fi

  # ウォッチのデータを取得
  if should_run "watch" "$@"; then get_watch; fi

  # データ取得後のRateLimitを出力
  get_ratelimit "after:get-data()" "$before_remaining_ratelimit" "false"
}
