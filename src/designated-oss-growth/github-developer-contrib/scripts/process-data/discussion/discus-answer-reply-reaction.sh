#!/bin/bash

#--------------------------------------
# discussionへの回答のリプライにリアクションした人のデータを加工するファイル
#--------------------------------------

set -euo pipefail

#--------------------------------------
# 出力先のディレクトリを作成する
#--------------------------------------
readonly RESULT_PROCESSED_DISCUSSION_ANSWER_REPLY_REACTION_PATH="${RESULT_PROCESSED_DISCUSSION_DIR}/result-discus-answer-reply-reaction.json"
mkdir -p "$(dirname "$RESULT_PROCESSED_DISCUSSION_ANSWER_REPLY_REACTION_PATH")"

#--------------------------------------
# discussionへの回答のリプライにリアクションした人のデータを加工する関数
#--------------------------------------
function process_discussion_answer_reply_reaction() {

  printf '%s\n' "begin:process_discussion_answer_reply_reaction()"

  process_data_utils \
    --input-path "$RESULT_GET_DISCUSSION_ANSWER_REPLY_REACTION_PATH" \
    --output-path "$RESULT_PROCESSED_DISCUSSION_ANSWER_REPLY_REACTION_PATH" \
    --task-name "reaction" \
    --task-date "createdAt" \
    --author-field "user" \

  printf '%s\n' "end:process_discussion_answer_reply_reaction()"

  return 0
}
