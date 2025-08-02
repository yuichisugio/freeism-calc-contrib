#!/bin/bash

# pull request関連のデータ取得を行うファイル

set -euo pipefail

# プルリクエスト貢献者を分析。
function get_github_pull_request_contributors() {

  # 結果を格納する変数を先に宣言。
  # localも終了ステータスを持つので、↓と宣言と一緒に結果を入れると終了ステータスが正しく入らない。
  local result

  # ↓は、シェルスクリプトの静的解析ツールであるshellcheckに対して、GraphQL変数を使用したいので、""を使用する警告を無視して、''を使用できるように指示するもの。
  # shellcheck disable=SC2016
  result=$(
    gh api graphql -F owner="$OWNER" -F name="$REPO" -f query='
      query($owner: String!, $name: String!) {
        repository(owner: $owner, name: $name) {
          pullRequests(first: 100, orderBy: {field: CREATED_AT, direction: DESC}) {
            state
            nodes {
              author {
                login
                ... on User {
                  id
                  databaseId
                }
              }
            }
          }
        }
        rateLimit{
          cost
          limit
          nodeCount
          used
          remaining
          resetAt
        }
      }
  '
  )

  # 結果を返す
  echo "$result"

  # 終了ステータスを成功にする
  return 0
}
