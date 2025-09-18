#!/bin/bash

#--------------------------------------
# 各種の評価軸で重み付けの値を受け取った後に合計して、一覧にする
#--------------------------------------

set -euo pipefail

#--------------------------------------
# 使用するファイルを読み込む
#--------------------------------------
source "$(dirname "$0")/calc-amount-contrib.sh"

#--------------------------------------
# 出力先のファイルを作成する
#--------------------------------------
readonly CONTRIB_DIR="${OUTPUT_DIR}/contrib-data"
readonly CONTRIB_RESULT_PATH="${CONTRIB_DIR}/result-contrib.json"
mkdir -p "$(dirname "$CONTRIB_RESULT_PATH")"

#--------------------------------------
# 各種の評価軸で重み付けの値を受け取った後に合計して、一覧にする
#--------------------------------------
function calc_contrib() {
  calc_amount_contrib
}
