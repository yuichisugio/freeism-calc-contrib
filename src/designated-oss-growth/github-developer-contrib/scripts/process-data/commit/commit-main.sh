#!/bin/bash

#--------------------------------------
# コミットのデータ加工を統合するファイル
#--------------------------------------

set -euo pipefail

#--------------------------------------
# 出力先のファイルを定義
#--------------------------------------
readonly RESULT_PROCESSED_COMMIT_DIR="${OUTPUT_PROCESSED_DIR}/commit"
mkdir -p "$RESULT_PROCESSED_COMMIT_DIR"

#--------------------------------------
# 使用するファイルを読み込む
#--------------------------------------
source "${PROCESS_DIR}/commit/commit-node-id-with-pr.sh"
source "${PROCESS_DIR}/commit/commit-comment.sh"
source "${PROCESS_DIR}/commit/commit-comment-reaction.sh"

#--------------------------------------
# コミットのデータを加工する関数
#--------------------------------------
function process_commit() {

  printf '%s\n' "begin:process-commit()"

  # コミットのnode_idと各種フィールドのtotalCountを取得
  process_commit_node_id_with_pr

  # コミットのコメントを取得
  process_commit_comment

  # コミットのコメントにリアクションした人のデータを取得
  process_commit_comment_reaction

  printf '%s\n' "end:process-commit()"

  return 0
}
