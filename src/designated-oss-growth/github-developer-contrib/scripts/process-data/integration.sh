#!/bin/bash

#--------------------------------------
# データ加工を統合するファイル
#--------------------------------------

set -euo pipefail

# --------------------------------------
# 出力先のディレクトリを作成する
# --------------------------------------
readonly OUTPUT_PROCESSED_DIR="${OUTPUT_DIR}/processed-data"
mkdir -p "$OUTPUT_PROCESSED_DIR"

#--------------------------------------
# 使用するファイルを読み込む
#--------------------------------------
readonly PROCESS_DIR="${SCRIPT_DIR}/scripts/process-data"
source "${PROCESS_DIR}/process-data-utils.sh"
# source "${PROCESS_DIR}/issue/issue-main.sh"
# source "${PROCESS_DIR}/discussion/discus-main.sh"
# source "${PROCESS_DIR}/commit/commit-main.sh"
# source "${PROCESS_DIR}/pull-request/pr-main.sh"
# source "${PROCESS_DIR}/release/release-main.sh"
source "${PROCESS_DIR}/star.sh"
source "${PROCESS_DIR}/fork.sh"
source "${PROCESS_DIR}/watch.sh"
source "${PROCESS_DIR}/sponsor.sh"
source "${PROCESS_DIR}/repo-meta.sh"

#--------------------------------------
# データ加工を統合する関数
#--------------------------------------
function process_data() {
  printf '%s\n' "begin:process_data()"
  process_star
  # process_commit
  # process_discussion
  process_fork
  # process_issue
  # process_pull_request
  # process_release
  process_repo_meta
  process_sponsor
  process_watch
  printf '%s\n' "end:process_data()"
}
