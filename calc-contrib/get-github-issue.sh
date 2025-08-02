#!/bin/bash

# issue関連のデータ取得を行うファイル

set -euo pipefail

# 出力ファイルのパス
OUTPUT_DIR="./results/issue"
OUTPUT_FILE="${OUTPUT_DIR}/issue_contributors_${OWNER}_${REPO}_$(date +%Y%m%d_%H%M%S).csv"

function get_github_issue_contributors() {
    # shellcheck disable=SC2016
  gh api graphql -F owner="$OWNER" -F name="$REPO" -f query='
      query($owner: String!, $name: String!) {
        repository(owner: $owner, name: $name) {
          issues(first: 100, orderBy: {field: CREATED_AT, direction: DESC}) {
            totalCount
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
  ' |
    jq -r '
    # プルリクエストデータの前処理
    .data.repository.issues as $issues |

    # 作成者情報を抽出・整理（null値を除外）
    $issues.nodes
    | map(select(.author != null and .author.login != null))
    | map({
        userId: (.author.databaseId),
        username: .author.login
      })

    # ユーザーごとに集計
    | group_by(.username)
    | map({
        userId: .[0].userId,
        username: .[0].username,
        issueCount: length
      })

    # 貢献度順にソート（降順）
    | sort_by(-.issueCount)

    # CSVヘッダーの出力
    | (["userId", "username", "issueCount"] | join(",")),

    # データ行の出力
    (.[] | [.userId, .username, .issueCount] | @csv)
    ' |
    tee "$OUTPUT_FILE"
}
