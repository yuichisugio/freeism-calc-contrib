#!/bin/bash

#--------------------------------------
# リポジトリのメタデータを取得する
#--------------------------------------

set -euo pipefail

#--------------------------------------
# 出力先のファイルを作成する
#--------------------------------------
readonly RAW_REPO_META_DIR="${RESULTS_GET_DIR}/result-repo-meta.json"

#--------------------------------------
# リポジトリのメタデータを取得する
#--------------------------------------
function get_repo_meta() {

  # データ取得前のRateLimit変数
  local before_remaining_ratelimit
  # データ取得前のRateLimitを取得
  before_remaining_ratelimit="$(get_ratelimit "before:get-repo-meta()")"

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

  # データ取得後のRateLimitを出力
  get_ratelimit "after:get-repo-meta()" "$before_remaining_ratelimit" "false"
}
