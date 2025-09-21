#!/bin/bash

#--------------------------------------
# pull-requestのコメントにリアクションした人のデータを加工するファイル
#--------------------------------------

set -euo pipefail

#--------------------------------------
# 出力先のディレクトリを作成する
#--------------------------------------
readonly RESULT_PROCESSED_PR_COMMENT_REACTION_PATH="${RESULT_PROCESSED_PR_DIR}/result-pr-comment-reaction.json"
mkdir -p "$(dirname "$RESULT_PROCESSED_PR_COMMENT_REACTION_PATH")"

#--------------------------------------
# pull-requestのコメントにリアクションした人のデータを加工する関数
#--------------------------------------
function process_pr_comment_reaction() {

  printf '%s\n' "begin:process_pr_comment_reaction()"

  process_data_utils \
    --input-path "$RESULT_GET_PR_COMMENT_REACTION_PATH" \
    --output-path "$RESULT_PROCESSED_PR_COMMENT_REACTION_PATH" \
    --task-name "reaction" \
    --task-date "createdAt" \
    --author-field "user" \

  printf '%s\n' "end:process_pr_comment_reaction()"

  return 0
}
