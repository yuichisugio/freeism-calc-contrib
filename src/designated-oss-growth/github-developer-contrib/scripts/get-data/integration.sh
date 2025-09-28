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
source "${GET_DIR}/issue/issue-main.sh"
source "${GET_DIR}/discussion/discus-main.sh"
source "${GET_DIR}/commit/commit-main.sh"
source "${GET_DIR}/pull-request/pr-main.sh"
source "${GET_DIR}/release/release-main.sh"
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

  # どんなタスクが選ばれても必須で、リポジトリのメタデータを取得する。
  get_repo_meta

  # 実行するファイルを選択
  if should_run \
    "commit" \
    "create_commit_with_pr" \
    "comment" \
    "reaction" \
    -- "$@"; then
    get_commit
  fi

  if should_run \
    "discussion" \
    "create_discussion" \
    "answer_discussion" \
    "comment" \
    "reaction" \
    -- "$@"; then
    get_discussion
  fi

  if should_run "fork" -- "$@"; then get_fork; fi

  if should_run \
    "issue" \
    "create_issue" \
    "change_issue_state" \
    "assigning" \
    "labeling" \
    "comment" \
    "reaction" \
    -- "$@"; then
    get_issue
  fi

  if should_run \
    "pull-request" \
    "create_pull_request" \
    "change_pull_request_state" \
    "assigning" \
    "labeling" \
    "pr_review" \
    "comment" \
    "reaction" \
    -- "$@"; then
    get_pull_request
  fi

  if should_run \
    "release" \
    "create_release" \
    "reaction" \
    -- "$@"; then
    get_release
  fi

  if should_run "sponsor" -- "$@"; then get_sponsor; fi
  if should_run "star" -- "$@"; then get_star; fi
  if should_run "watch" -- "$@"; then get_watch; fi

  # データ取得後のRateLimitを出力
  get_ratelimit "after:get-data()" "$before_remaining_ratelimit" "false"
}
