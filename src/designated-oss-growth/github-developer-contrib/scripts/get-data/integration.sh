#!/bin/bash

#--------------------------------------
# GraphQL APIのクエリを統合するファイル
#--------------------------------------

set -euo pipefail

cd "$(cd "$(dirname -- "$0")" && pwd -P)"

function integration_graphql_query() {

  # 引数の値
  local owner="$1" repo="$2"

  get_repo_meta "$owner" "$repo"

  # 終了ステータスを成功にする
  return 0
}

integration_graphql_query "$@" || exit 1
