#!/bin/bash

#--------------------------------------
# メインスクリプト
# 実行したい時に呼び出すファイル。ここを起点に色々な関数を呼び出す
#--------------------------------------

# エラーが発生でスクリプトを終了。未定義でエラー。パイプ中エラーでも中断
set -euo pipefail

# スクリプトのディレクトリに移動。
# どのディレクトリにいても、スクリプトのディレクトリに移動することで相対パスでファイルでも正しく指定できる。
cd "$(cd "$(dirname -- "$0")" && pwd -P)"

# 共通関数を読み込む
source "$(dirname "$0")/scripts/utils/utils.sh"

# ヘルプオプションの処理。
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  show_usage
  exit 0
fi

readonly RESULTS_DIR="./results/${OWNER}/${REPO}"
readonly RAW_DIR="${RESULTS_DIR}/raw-data"
readonly RAW_REPO_META_DIR="${RAW_DIR}/repo-meta"
readonly RAW_INTEGRATION_DIR="${RAW_DIR}/integration"
readonly RAW_PULL_REQUEST_DIR="${RAW_DIR}/pull-request"
readonly PROCESSED_DIR="${RESULTS_DIR}/processed-data"
readonly PROCESSED_REPO_META_DIR="${PROCESSED_DIR}/repo-meta"
readonly PROCESSED_INTEGRATION_DIR="${PROCESSED_DIR}/integration"
readonly PROCESSED_PULL_REQUEST_DIR="${PROCESSED_DIR}/pull-request"
readonly PROCESSED_ISSUE_DIR="${PROCESSED_DIR}/issue"

readonly PATH_ARRAY=(
  "${RAW_DIR}"
  "${RAW_REPO_META_DIR}"
  "${RAW_INTEGRATION_DIR}"
  "${RAW_PULL_REQUEST_DIR}"
  "${PROCESSED_DIR}"
  "${PROCESSED_REPO_META_DIR}"
  "${PROCESSED_INTEGRATION_DIR}"
  "${PROCESSED_PULL_REQUEST_DIR}"
  "${PROCESSED_ISSUE_DIR}"
)

# データを加工するファイルを読み込む
source "$(dirname "$0")/scripts/process-data/github-processor.sh"

# プルリクエスト貢献者を分析。
source "$(dirname "$0")/scripts/get-data/pull-request.sh"

# イシュー貢献者を分析。
source "$(dirname "$0")/scripts/get-data/issue.sh"

# 貢献度の重み付け
# source "$(dirname "$0")/calc-contrib/contrib-weighting.sh"

# 貢献度の合計を計算する
# source "$(dirname "$0")/calc-contrib/calc-amount-contrib.sh"

# メイン関数
function main() {

  # 依存コマンドの確認
  require_tools

  # 引数をパース
  read -r OWNER REPO < <(parse_github_url_args "$@")

  # 出力ディレクトリの準備
  setup_output_directory "$OWNER" "$REPO"

  # プルリクエスト貢献者を分析。
  raw_pr_data=$(get_github_pull_request_contributors)
  processed_pr_data=$(process_pr_data "$raw_pr_data")
  echo "$processed_pr_data"

  # イシュー貢献者を分析。
  raw_issue_data=$(get_github_issue_contributors)
  processed_issue_data=$(process_issue_data "$raw_issue_data")
  echo "$processed_issue_data"

  return 0
}

# スクリプトを実行。
main "$@"
