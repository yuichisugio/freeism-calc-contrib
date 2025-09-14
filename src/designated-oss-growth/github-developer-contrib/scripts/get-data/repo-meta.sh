#!/bin/bash

#--------------------------------------
# リポジトリのメタデータを取得する
#--------------------------------------

set -euo pipefail

#--------------------------------------
# 出力先のファイルを作成する
#--------------------------------------
readonly RAW_REPO_META_DIR="${RAW_DIR}/repo-meta.json"
mkdir -p "$(dirname "$RAW_REPO_META_DIR")"


#--------------------------------------
# リポジトリのメタデータを取得する
#--------------------------------------
function get_repo_meta() {

  local QUERY

  # クエリを定義
  # shellcheck disable=SC2016
  QUERY='
    query($owner: String!, $repo: String!) {
      repository(owner: $owner, name: $repo) {
        id
        name
        url
        createdAt
        owner {
          login
          id
        }
        defaultBranchRef {
          name
        }
      }
    }
  '

  # クエリを実行。jq '.' で、JSONを整形して指定ファイルに出力。
  gh api graphql -F owner="$OWNER" -F repo="$REPO" -f query="$QUERY" | jq '.' >"$RAW_REPO_META_DIR"
}
