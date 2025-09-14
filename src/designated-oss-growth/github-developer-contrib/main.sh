#!/bin/bash

#--------------------------------------
# メインスクリプト
# 実行したい時に呼び出すファイル。ここを起点に色々な関数を呼び出す
#--------------------------------------

#--------------------------------------
# 準備（エラー対応、相対PATH安定）
#--------------------------------------
set -euo pipefail

cd "$(cd "$(dirname -- "$0")" && pwd -P)"

#--------------------------------------
# 引数のパース＆取得
#--------------------------------------
read -r OWNER REPO SINCE UNTIL < <(parse_args "$@")

#--------------------------------------
# 出力ディレクトリの準備
#--------------------------------------
readonly RESULTS_DIR="./results/${OWNER}/${REPO}"

# readonly RAW_PULL_REQUEST_DIR="${RAW_DIR}/pull-request.json"
# readonly RAW_SPONSOR_DIR="${RAW_DIR}/sponsor.json"
# readonly RAW_FORK_DIR="${RAW_DIR}/fork.json"
# readonly RAW_WATCH_DIR="${RAW_DIR}/watch.json"
# readonly RAW_ISSUE_DIR="${RAW_DIR}/issue.json"
# readonly RAW_COMMENT_DIR="${RAW_DIR}/comment.json"
# readonly RAW_REACTION_DIR="${RAW_DIR}/reaction.json"

readonly PROCESSED_DIR="${RESULTS_DIR}/processed-data"
# readonly PROCESSED_REPO_META_DIR="${PROCESSED_DIR}/repo-meta"
# readonly PROCESSED_PULL_REQUEST_DIR="${PROCESSED_DIR}/pull-request"
# readonly PROCESSED_ISSUE_DIR="${PROCESSED_DIR}/issue"
# readonly PROCESSED_COMMENT_DIR="${PROCESSED_DIR}/comment"
# readonly PROCESSED_REACTION_DIR="${PROCESSED_DIR}/reaction"

readonly WEIGHTED_DIR="${RESULTS_DIR}/weighted-data"

readonly CONTRIB_DIR="${RESULTS_DIR}/contrib-data"

readonly RESULT_DIR="${RESULTS_DIR}/result"

readonly CREATE_PATH_ARRAY=(
  "${RAW_DIR}"
  "${PROCESSED_DIR}"
  "${WEIGHTED_DIR}"
  "${CONTRIB_DIR}"
  "${RESULT_DIR}"
)

#--------------------------------------
# 使用するファイルを読み込む
#--------------------------------------
# 共通関数を読み込む
source "$(dirname "$0")/scripts/utils/utils.sh"

# データ取得を統合するファイル/それに使用するファイルを取得
source "$(dirname "$0")/scripts/get-data/integration.sh"

# データ加工を統合するファイルを取得
# source "$(dirname "$0")/scripts/process-data/integration.sh"

# 重み付けを統合するファイルを取得
# source "$(dirname "$0")/scripts/calc-weighting/integration.sh"

# 貢献度の算出を統合するファイルを取得
# source "$(dirname "$0")/scripts/calc-contrib/integration.sh"

# メイン関数
function main() {

  # データ取得前のRateLimit変数
  local before_remaining_ratelimit

  # 依存コマンドの確認
  require_tools

  # データ取得前のRateLimitを取得
  before_remaining_ratelimit="$(get_ratelimit "before:main()")"

  # 出力ディレクトリの準備
  setup_output_directory

  # データ取得
  get_data

  # データ加工
  process_data

  # 重み付け
  calc_weighting

  # 貢献度の算出
  calc_contrib

  # 結果の出力
  output_result

  # データ取得後のRateLimitを出力
  get_ratelimit "after:main()" "$before_remaining_ratelimit"

  return 0
}

# スクリプトを実行。
main "$@"
