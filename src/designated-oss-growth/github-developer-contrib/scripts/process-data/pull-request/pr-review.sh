#!/bin/bash

#--------------------------------------
# pull-requestをレビューした人のデータを加工するファイル
#--------------------------------------

set -euo pipefail

#--------------------------------------
# 出力先のディレクトリを作成する
#--------------------------------------
readonly RESULT_PROCESSED_PR_REVIEW_PATH="${RESULT_PROCESSED_PR_DIR}/result-pr-review.json"
mkdir -p "$(dirname "$RESULT_PROCESSED_PR_REVIEW_PATH")"

#--------------------------------------
# pull-requestをレビューした人のデータを加工する関数
#--------------------------------------
function process_pr_review() {

  printf '%s\n' "begin:process_pr_review()"

  # shellcheck disable=SC2016
  local SECOND_OTHER_QUERY='
    review_word_count:   (.bodyText? // "" | length),
    pr_start_date: $obj.node_publishedAt,
    pr_word_count:(($obj.node_title? // "" | length)+($obj.node_bodyText? // "" | length)),
    pr_change_record_count:(($obj.node_additions? // 0)+($obj.node_deletions? // 0)),
    good_reaction:
      (
        ( $obj.reactionGroups? // [] )
        | map(
          if (.content // "") == "THUMBS_DOWN"
            then 0
            else (.reactors.totalCount // 0)
            end
          )
        | add // 0
      ),

    bad_reaction:
      (
        ( $obj.reactionGroups? // [] )
        | map(
            if (.content // "") == "THUMBS_DOWN"
            then (.reactors.totalCount // 0)
            else 0
            end
          )
        | add // 0
      )
  '

  process_data_utils \
    --input-path "$RESULT_GET_PR_REVIEW_NODE_ID_PATH" \
    --output-path "$RESULT_PROCESSED_PR_REVIEW_PATH" \
    --task-name "pr-review" \
    --task-date "publishedAt" \
    --author-field "author" \
    --second-other-query "$SECOND_OTHER_QUERY"

  printf '%s\n' "end:process_pr_review()"

  return 0
}
