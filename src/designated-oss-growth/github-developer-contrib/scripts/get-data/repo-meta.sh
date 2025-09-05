#!/bin/bash

#--------------------------------------
# リポジトリのメタデータを取得する
#--------------------------------------

set -euo pipefail

cd "$(cd "$(dirname -- "$0")" && pwd -P)"

function get_repo_meta() {
  # 引数の値
  local owner="$1" repo="$2" query RAW_DATA_PATH PROCESSED_DATA_PATH

  # ファイルのデータのパスを設定
  readonly RAW_DATA_PATH="./raw-data.json"
  readonly PROCESSED_DATA_PATH="../../archive/processed-data.json"

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
  gh api graphql -F owner="$owner" -F repo="$repo" -f query="$query" | jq '.' >"$RAW_DATA_PATH"

  # 終了ステータスを成功にする
  return 0
}

get_repo_meta "$@"
