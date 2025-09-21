#!/bin/bash

#--------------------------------------
# issueのコメントにリアクションした人のデータを加工するファイル
#--------------------------------------

set -euo pipefail

#--------------------------------------
# 出力先のディレクトリを作成する
#--------------------------------------
readonly RESULT_PROCESSED_ISSUE_COMMENT_REACTION_PATH="${RESULT_PROCESSED_ISSUE_DIR}/result-issue-comment-reaction.json"
mkdir -p "$(dirname "$RESULT_PROCESSED_ISSUE_COMMENT_REACTION_PATH")"

#--------------------------------------
# issueのコメントにリアクションした人のデータを加工する関数
#--------------------------------------
function process_issue_comment_reaction() {

  printf '%s\n' "begin:process_issue_comment_reaction()"

  process_data_utils \
    --input-path "$RESULT_GET_ISSUE_COMMENT_REACTION_PATH" \
    --output-path "$RESULT_PROCESSED_ISSUE_COMMENT_REACTION_PATH" \
    --task-name "reaction" \
    --task-date "createdAt" \
    --author-field "user" \

  printf '%s\n' "end:process_issue_comment_reaction()"

  return 0
}
