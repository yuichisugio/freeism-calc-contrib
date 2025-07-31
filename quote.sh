#!/bin/bash

# エラーが発生したらスクリプトを終了。
# -eはエラーが発生したらスクリプトを終了。
# -uは未定義の変数を使用したらエラー。
# -oはパイプで繋いだコマンドが失敗したらスクリプトを終了。
set -euo pipefail

# スクリプトのディレクトリに移動。
# どのディレクトリにいても、スクリプトのディレクトリに移動することで相対パスでファイルでも正しく指定できる。
cd "$(dirname "$0")"

# 使用方法の表示
show_usage() {
  cat <<EOF
Usage: $0 [OWNER] [REPO]

GitHub リポジトリのプルリクエスト貢献者を分析し、
各ユーザーの貢献度をCSV形式で出力します。

Parameters:
  OWNER    リポジトリのオーナー名 (デフォルト: cli)
  REPO     リポジトリ名 (デフォルト: cli)

Output:
  userId,username,pullrequest回数

Examples:
  $0                    # cli/cli を分析
  $0 facebook react     # facebook/react を分析
  $0 microsoft vscode   # microsoft/vscode を分析

EOF
}

# ヘルプオプションの処理
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  show_usage
  exit 0
fi

# デフォルト設定
OWNER=${1:-"yoshiko-pg"}
REPO=${2:-"difit"}

# 出力ファイルのパス
OUTPUT_DIR="./reports"
OUTPUT_FILE="${OUTPUT_DIR}/pr_contributors_${OWNER}_${REPO}_$(date +%Y%m%d_%H%M%S).csv"

# プルリクエスト貢献者を分析。
function analyze_contributors() {
  # GitHub APIを呼び出し、プルリクエストデータを取得。
  # jqでデータを加工してCSVに出力。
  # teeでファイルに出力しつつ、標準出力にも出力。
  gh api graphql -F owner="$OWNER" -F name="$REPO" -f query='  
    query($name: String!, $owner: String!) {
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
  ' | jq -r '
# プルリクエストデータの前処理
.data.repository.pullRequests as $pullRequests |

# 作成者情報を抽出・整理（null値を除外）
$pullRequests.nodes 
| map(select(.author != null and .author.login != null))
| map({
    userId: (.author.databaseId // "unknown"),
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
| (["userId", "username", "pullrequest回数"] | @csv),
  
# データ行の出力
(.[] | [.userId, .username, .pullRequestCount] | @csv)
' | tee "$OUTPUT_FILE"
}

# 出力ディレクトリの準備
setup_output_directory() {
  if [[ ! -d "$OUTPUT_DIR" ]]; then
    mkdir -p "$OUTPUT_DIR"
  fi
}

# メイン関数
function main() {
  setup_output_directory
  analyze_contributors
}

# スクリプトを実行。
main "$@"
