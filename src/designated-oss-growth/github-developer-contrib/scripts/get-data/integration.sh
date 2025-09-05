#!/bin/bash

#--------------------------------------
# GraphQL APIのクエリを統合するファイル
#--------------------------------------

set -euo pipefail

cd "$(cd "$(dirname -- "$0")" && pwd -P)"

function integration_graphql_query() {
  # 引数の値
  local owner="$1" repo="$2" output_file="$3" query

  # クエリを定義
  # shellcheck disable=SC2016
  query='
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

  # クエリを実行。jq '.' で、JSONを指定ファイルに出力。
  gh api graphql -F owner="$owner" -F repo="$repo" -f query="$query" | jq '.' >"$output_file"

  # 終了ステータスを成功にする
  return 0
}

integration_graphql_query "$@" || exit 1
