#!/bin/bash

# 評価軸「OSS業界全体の発展」で分析するシェルスクリプトのメインファイル

set -euo pipefail

cd "$(dirname "$0")"

# デフォルト設定
# readonly OWNER=${1:-"yoshiko-pg"}
# readonly REPO=${2:-"difit"}
# readonly GITHUB_AUTH_TOKEN=${3}
readonly RESULTS_DIR="./results"
readonly PULL_REQUEST_DIR="${RESULTS_DIR}/pull-request"
readonly ISSUE_DIR="${RESULTS_DIR}/issue"

# 共通関数を読み込む
source "$(dirname "$0")/scripts/utils/utils.sh"

# ヘルプオプションの処理。引数がある場合のみヘルプをチェック。
# 引数がない場合はヘルプを表示しない。
if [[ $# -gt 0 && ("$1" == "-h" || "$1" == "--help") ]]; then
  show_usage
  exit 0
fi

# データを加工するファイルを読み込む
source "$(dirname "$0")/scripts/data-process/github-processor.sh"

# データを加工するファイルを読み込む
source "$(dirname "$0")/scripts/data-process/scorecard-processor.sh"

# プルリクエスト貢献者を分析。
source "$(dirname "$0")/scripts/get-data/from-github/github-oss-meta-data.sh"

# イシュー貢献者を分析。
# source "$(dirname "$0")/scripts/get-data/from-open-ssf-scorecard/scorecard.sh"

# 貢献度の重み付け
# source "$(dirname "$0")/calc-contrib/contrib-weighting.sh"

# 貢献度の合計を計算する
# source "$(dirname "$0")/calc-contrib/calc-amount-contrib.sh"

# メイン関数
function main() {
  # 出力ディレクトリの準備
  setup_output_directory

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
main
