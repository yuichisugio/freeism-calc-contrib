#!/bin/bash

#--------------------------------------
# データ加工を統合するファイル
#--------------------------------------

set -euo pipefail

# --------------------------------------
# 出力先のディレクトリ/ファイルを作成する
# --------------------------------------
# 加工したデータを入れるディレクトリ
readonly OUTPUT_PROCESSED_DIR="${OUTPUT_DIR}/processed-data"
mkdir -p "$OUTPUT_PROCESSED_DIR"
# 統合したデータのパス
readonly RESULT_PROCESSED_INTEGRATED_DATA_PATH="${OUTPUT_PROCESSED_DIR}/integrated-processed-data.json"

#--------------------------------------
# 使用するファイルを読み込む
#--------------------------------------
readonly PROCESS_DIR="${SCRIPT_DIR}/scripts/process-data"
source "${PROCESS_DIR}/npm-downloads.sh"
source "${PROCESS_DIR}/github-star.sh"

#--------------------------------------
# データ加工を統合する関数
#--------------------------------------
function process_data() {

  printf '%s\n' "begin:process_data()"

  process_npm_downloads
  process_github_star

  printf '%s\n' "end:process_data()"
}
