#!/bin/bash

#--------------------------------------
# プルリクエストのレビューにリアクションした人のデータを加工するファイル
#--------------------------------------

set -euo pipefail

#--------------------------------------
# 出力先のディレクトリを作成する
#--------------------------------------
readonly RESULT_PROCESSED_PR_REVIEW_REACTION_PATH="${RESULT_PROCESSED_PR_DIR}/result-pr-review-reaction.json"
mkdir -p "$(dirname "$RESULT_PROCESSED_PR_REVIEW_REACTION_PATH")"

#--------------------------------------
# プルリクエストのレビューにリアクションした人のデータを加工する関数
#--------------------------------------
function process_pr_review_reaction() {

  printf '%s\n' "begin:process_pr_review_reaction()"

  process_data_utils \
    --input-path "$RESULT_GET_PR_REVIEW_REACTION_PATH" \
    --output-path "$RESULT_PROCESSED_PR_REVIEW_REACTION_PATH" \
    --task-name "reaction" \
    --task-date "createdAt" \
    --author-field "user" \

  printf '%s\n' "end:process_pr_review_reaction()"

  return 0
}
