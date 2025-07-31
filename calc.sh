#!/bin/bash
# GitHub プルリクエスト貢献者分析ツール

# ./calc.sh yoshiko-pg difit 2> error.txt

# エラーが発生したらスクリプトを終了。-xは標準エラー出力なので、error.txtに出力させる。
set -euxo pipefail

# デフォルト設定
OWNER=${1:-"yoshiko-pg"}
REPO=${2:-"difit"}

# 出力ファイルのパス
OUTPUT_DIR="./reports"
OUTPUT_FILE="${OUTPUT_DIR}/pr_contributors_${OWNER}_${REPO}_$(date +%Y%m%d_%H%M%S).csv"

# 使用方法の表示
show_usage() {
    cat << EOF
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

# 必要なコマンドの確認
check_requirements() {
    local missing_commands=()
    
    command -v gh >/dev/null 2>&1 || missing_commands+=("gh")
    command -v jq >/dev/null 2>&1 || missing_commands+=("jq")
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        echo "❌ Error: Missing required commands: ${missing_commands[*]}" >&2
        echo "Please install the missing commands and try again." >&2
        exit 1
    fi
}

# GitHub認証確認
check_github_auth() {
    if ! gh auth status >/dev/null 2>&1; then
        echo "❌ Error: GitHub CLI is not authenticated." >&2
        echo "Please run 'gh auth login' first." >&2
        exit 1
    fi
}

# リポジトリアクセス確認
check_repository_access() {
    echo "🔍 Checking repository access..."
    if ! gh repo view "$OWNER/$REPO" >/dev/null 2>&1; then
        echo "❌ Error: Repository $OWNER/$REPO not found or not accessible." >&2
        echo "Please check the repository name and your access permissions." >&2
        exit 1
    fi
    echo "✅ Repository access confirmed"
}

# 出力ディレクトリの準備
setup_output_directory() {
    if [[ ! -d "$OUTPUT_DIR" ]]; then
        mkdir -p "$OUTPUT_DIR"
    fi
}

# メイン分析処理
analyze_contributors() {
    echo ""
    echo "📊 Starting pull request contributor analysis..."
    echo "Repository: $OWNER/$REPO"
    echo "Output file: $OUTPUT_FILE"
    echo "----------------------------------------"
    
    # データ取得と処理
    gh api graphql \
      --field owner="$OWNER" \
      --field repo="$REPO" \
      --field query='
        query($owner: String!, $repo: String!) {
          repository(owner: $owner, name: $repo) {
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
        }
      ' | \
    jq '
      # プルリクエストの総数を取得（参考情報として）
      .data.repository.pullRequests.totalCount as $total |
      
      # 作成者情報を抽出・整理
      .data.repository.pullRequests.nodes 
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
      
      # 貢献度順にソート
      | sort_by(-.pullRequestCount)
      
      # メタデータを追加
      | {
          metadata: {
            totalPullRequests: $total,
            analyzedDate: now | strftime("%Y-%m-%d %H:%M:%S"),
            contributorCount: length
          },
          contributors: .
        }
    ' | \
    gh api --template '
{{/* メタデータをコメントとして出力 */}}
# Pull Request Contributor Analysis Report
# Repository: '"$OWNER/$REPO"'
# Generated: {{.metadata.analyzedDate}}
# Total Contributors: {{.metadata.contributorCount}}
# ----------------------------------------
userId,username,pullrequest回数
{{/* 各貢献者の情報を出力 */}}
{{range .contributors}}
{{.userId}},"{{.username | replace "\"" "\"\""}}",{{.pullRequestCount}}
{{end}}
' --input - | \
    tee "$OUTPUT_FILE"
    
    echo ""
    echo "----------------------------------------"
    echo "✅ Analysis completed successfully!"
    echo "📁 Report saved: $OUTPUT_FILE"
    echo "📈 Contributors found: $(( $(grep -c "^[0-9]" "$OUTPUT_FILE") ))"
    echo "💾 File size: $(du -h "$OUTPUT_FILE" | cut -f1)"
}

# メイン実行関数
main() {
    echo "🚀 GitHub Pull Request Contributor Analyzer"
    echo "==========================================="
    
    # 事前チェック
    check_requirements
    check_github_auth
    check_repository_access
    setup_output_directory
    
    # 分析実行
    analyze_contributors
    
    echo ""
    echo "🎉 All done! Happy analyzing!"
}

# スクリプト実行
main "$@"
