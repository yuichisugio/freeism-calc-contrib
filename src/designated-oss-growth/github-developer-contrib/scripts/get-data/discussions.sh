#!/bin/bash

#--------------------------------------
# discussions関連のデータ取得を行うファイル
#--------------------------------------

set -euo pipefail

cd "$(cd "$(dirname -- "$0")" && pwd -P)"

function get_discussions() {
  local owner="$1" repo="$2"

  # クエリを定義
  # shellcheck disable=SC2016
  QUERY='
    query($owner: String!, $repo: String!) {
      repository(owner: $owner, name: $repo) {
        discussions(first: 50) {
          nodes {
            id
            title
            body
          }
        }
      }
    }
  '

  # クエリを実行。jq '.' で、JSONを指定ファイルに出力。
  gh api graphql -F owner="$owner" -F repo="$repo" -f query="$QUERY" | jq '.' >"$RAW_DISCUSSIONS_DIR"

  # 終了ステータスを成功にする
  return 0
}

get_discussions "$@"
