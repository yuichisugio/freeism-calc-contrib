#!/bin/bash

#--------------------------------------
# commitと紐づくPR一覧の作成者のデータを加工するファイル
#--------------------------------------

set -euo pipefail

#--------------------------------------
# 出力先のディレクトリを作成する
#--------------------------------------
readonly RESULT_PROCESSED_COMMIT_NODE_ID_WITH_PR_PATH="${RESULT_PROCESSED_COMMIT_DIR}/result-commit-node-id-with-pr.json"
mkdir -p "$(dirname "$RESULT_PROCESSED_COMMIT_NODE_ID_WITH_PR_PATH")"

#--------------------------------------
# commit作成者のデータを加工する関数
#--------------------------------------
function process_commit_node_id_with_pr() {

  printf '%s\n' "begin:process_commit_node_id_with_pr()"

  # shellcheck disable=SC2016
  local FIRST_OTHER_QUERY='
    {
      data: {
        user: (
          [ .[]?
            | . as $obj
            | (.authors.nodes // [])[]
            | . as $a
            | ($a.user // empty) as $author
  '

  # shellcheck disable=SC2016
  local SECOND_OTHER_QUERY='
    word_count:(($obj.name? // "" | length) + ($obj.description? // "" | length)),
    reaction:  ($obj.reactions.totalCount // 0)
  '

  process_data_utils \
    --input-path "$RESULT_GET_COMMIT_NODE_ID_WITH_PR_PATH" \
    --output-path "$RESULT_PROCESSED_COMMIT_NODE_ID_WITH_PR_PATH" \
    --task-name "create-commit-with-pr" \
    --task-date "authoredDate" \
    --author-field "authors" \
    --first-other-query "$FIRST_OTHER_QUERY" \
    --second-other-query "$SECOND_OTHER_QUERY"

  printf '%s\n' "end:process_commit_node_id_with_pr()"

  return 0
}
