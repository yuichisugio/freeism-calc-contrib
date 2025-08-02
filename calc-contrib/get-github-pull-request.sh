#!/bin/bash

# pull request関連のデータ取得を行うファイル

# エラーが発生したらスクリプトを終了。
# -eはエラーが発生したらスクリプトを終了。
# -uは未定義の変数を使用したらエラー。
# -oはパイプで繋いだコマンドが失敗したらスクリプトを終了。
set -euo pipefail

# 出力ファイルのパス
OUTPUT_DIR="./results/pull-request"
OUTPUT_FILE="${OUTPUT_DIR}/pr_contributors_${OWNER}_${REPO}_$(date +%Y%m%d_%H%M%S).csv"

# プルリクエスト貢献者を分析。
function get_github_pull_request_contributors() {
  # GitHub APIを呼び出し、プルリクエストデータを取得。
  # jqでデータを加工してCSVに出力。
  # teeでファイルに出力しつつ、標準出力にも出力。

  # ↓ディレクティブは、シェルスクリプトの静的解析ツールであるshellcheckに対して、GraphQL変数を使用したいので、""を使用する警告を無視して、''を使用できるように指示するもの。
  # shellcheck disable=SC2016
  gh api graphql -F owner="$OWNER" -F name="$REPO" -f query='
      query($owner: String!, $name: String!) {
        repository(owner: $owner, name: $name) {
          pullRequests(first: 100, orderBy: {field: CREATED_AT, direction: DESC}) {
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
    .data.repository.pullRequests as $pullRequests |

    # 作成者情報を抽出・整理（null値を除外）
    $pullRequests.nodes
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
        pullRequestCount: length
      })

    # 貢献度順にソート（降順）
    | sort_by(-.pullRequestCount)

    # CSVヘッダーの出力
    | (["userId", "username", "pullRequestCount"] | join(",")),

    # データ行の出力
    (.[] | [.userId, .username, .pullRequestCount] | @csv)
    ' |
    tee "$OUTPUT_FILE"
}
