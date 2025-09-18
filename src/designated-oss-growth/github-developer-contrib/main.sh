#!/bin/bash

#--------------------------------------
# メインスクリプト
# 実行したい時に呼び出すファイル。ここを起点に色々な関数を呼び出す
#--------------------------------------

#--------------------------------------
# 準備（エラー対応、相対PATH安定）
#--------------------------------------
set -euo pipefail

# カレントディレクトリをスクリプトのディレクトリに固定
# shellcheck disable=SC2155
readonly SCRIPT_DIR="$(cd "$(dirname -- "$0")" && pwd -P)"
cd "$SCRIPT_DIR"

#--------------------------------------
# 共通関数を読み込む
#--------------------------------------
source "${SCRIPT_DIR}/scripts/utils/utils.sh"

#--------------------------------------
# 引数のパース＆取得。読み込に使用する必要がある
#--------------------------------------
if ! parsed="$(parse_args "$@")"; then
  # 関数内では>&2にしないとターミナル出力ができないが、そのままだとエラー表示になるので、ここでexit 0にすることで、エラー表示にせずにヘルプを出力できる。エラー表示は親プロセスで決まる。
  exit 0
fi
read -r OWNER REPO SINCE UNTIL <<<"$parsed"

#--------------------------------------
# 出力先のディレクトリを作成する
#--------------------------------------
# shellcheck disable=SC2155
readonly OUTPUT_DIR="${SCRIPT_DIR}/results/${OWNER}-${REPO}-${SINCE}-${UNTIL}-$(date +%Y%m%dT%H%M%S)"
mkdir -p "$OUTPUT_DIR"

#--------------------------------------
# 使用するファイルを読み込む
#--------------------------------------
# データ取得を統合するファイルを取得
source "${SCRIPT_DIR}/scripts/get-data/integration.sh"
# データ加工を統合するファイルを取得
# source "${SCRIPT_DIR}/scripts/process-data/integration.sh"
# 重み付けを統合するファイルを取得
# source "${SCRIPT_DIR}/scripts/calc-weighting/integration.sh"
# 貢献度の算出を統合するファイルを取得
# source "${SCRIPT_DIR}/scripts/calc-contrib/integration.sh"

#--------------------------------------
# メイン関数
#--------------------------------------
function main() {

  # 依存コマンドの確認
  require_tools

  # データ取得前のRateLimit変数
  local before_remaining_ratelimit
  # データ取得前のRateLimitを取得
  before_remaining_ratelimit="$(get_ratelimit "before:main()")"

  # データ取得
  get_data

  # # データ加工
  # process_data

  # # 重み付け
  # calc_weighting

  # # 貢献度の算出
  # calc_contrib

  # # 結果の出力
  # output_result

  # データ取得後のRateLimitを出力
  get_ratelimit \
    "after:main()" \
    "$before_remaining_ratelimit" \
    "false"

  return 0
}

# スクリプトを実行。
main "$@"
