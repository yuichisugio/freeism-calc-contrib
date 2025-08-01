#!/bin/bash

# 実行したい時に呼び出すファイル。ここを起点に色々な関数を呼び出す

# エラーが発生でスクリプトを終了。未定義でエラー。パイプ中エラーでも中断
set -euo pipefail

# スクリプトのディレクトリに移動。
# どのディレクトリにいても、スクリプトのディレクトリに移動することで相対パスでファイルでも正しく指定できる。
cd "$(dirname "$0")"

# デフォルト設定
OWNER=${1:-"yoshiko-pg"}
REPO=${2:-"difit"}

# 出力ファイルのパス
OUTPUT_DIR="./results/pull-request"
OUTPUT_FILE="${OUTPUT_DIR}/pr_contributors_${OWNER}_${REPO}_$(date +%Y%m%d_%H%M%S).csv"

# 共通関数を読み込む
source "$(dirname "$0")/calc-contrib/utils.sh"

# ヘルプオプションの処理。引数がある場合のみヘルプをチェック。
# 引数がない場合はヘルプを表示しない。
if [[ $# -gt 0 && ("$1" == "-h" || "$1" == "--help") ]]; then
  show_usage
  exit 0
fi

# プルリクエスト貢献者を分析。
source "$(dirname "$0")/calc-contrib/get-github-pull-request.sh" "$OWNER" "$REPO" "$OUTPUT_FILE"

# イシュー貢献者を分析。
source "$(dirname "$0")/calc-contrib/get-github-issue.sh" "$OWNER" "$REPO" "$OUTPUT_FILE"

# 貢献度の重み付け
# source "$(dirname "$0")/calc-contrib/contrib-weighting.sh"

# 貢献度の合計を計算する
# source "$(dirname "$0")/calc-contrib/calc-amount-contrib.sh"

# メイン関数
function main() {
  # 出力ディレクトリの準備
  setup_output_directory

  # プルリクエスト貢献者を分析。
  analyze_contributors
}

# スクリプトを実行。
main
