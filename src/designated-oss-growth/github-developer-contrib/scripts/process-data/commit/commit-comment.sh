#!/bin/bash

#--------------------------------------
# commit作成者のデータを加工するファイル
#--------------------------------------

set -euo pipefail

#--------------------------------------
# 出力先のディレクトリを作成する
#--------------------------------------
readonly RESULT_PROCESSED_COMMIT_COMMENT_PATH="${RESULT_PROCESSED_COMMIT_DIR}/result-commit-comment.json"
mkdir -p "$(dirname "$RESULT_PROCESSED_COMMIT_COMMENT_PATH")"

#--------------------------------------
# commit作成者のデータを加工する関数
#--------------------------------------
function process_commit_comment() {

  printf '%s\n' "begin:process_commit_comment()"

  local SECOND_OTHER_QUERY='
    word_count:   (.bodyText? // "" | length),
    good_reaction:
      (
        (.reactionGroups? // [] )
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
        (.reactionGroups? // [] )
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
    --input-path "$RESULT_GET_COMMIT_COMMENT_PATH" \
    --output-path "$RESULT_PROCESSED_COMMIT_COMMENT_PATH" \
    --task-name "comment" \
    --task-date "publishedAt" \
    --author-field "author" \
    --second-other-query "$SECOND_OTHER_QUERY"

  printf '%s\n' "end:process_commit_comment()"

  return 0
}
