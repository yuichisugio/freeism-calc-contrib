#!/bin/bash

#--------------------------------------
# コミットデータを取得する
#--------------------------------------

set -euo pipefail

cd "$(cd "$(dirname -- "$0")" && pwd -P)"

function get_commit() {
  local owner="$1" repo="$2" QUERY

  # shellcheck disable=SC2016
  QUERY='
    query($owner: String!, $repo: String!) {
      repository(owner: $owner, name: $repo) {
        commits(first: 100) {
          nodes {
            sha
            author { login }
            date: .commit.author.date
          }
        }
      }
    }
  '

  # コミットデータを取得
  gh api graphql -F owner="$owner" -F repo="$repo" -f query="$QUERY" >"$RAW_COMMIT_DIR"

  return 0
}

get_commit "$@"
