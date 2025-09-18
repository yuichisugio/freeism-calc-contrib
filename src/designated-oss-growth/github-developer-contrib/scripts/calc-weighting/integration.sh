#!/bin/bash

#--------------------------------------
# 各種の評価軸で重み付けの値を受け取った後に合計して、一覧にする
#--------------------------------------

set -euo pipefail

#--------------------------------------
# 使用するファイルを読み込む
#--------------------------------------
source "$(dirname "$0")/calc-task-type-weighting.sh"
source "$(dirname "$0")/calc-period-weighting.sh"
source "$(dirname "$0")/calc-lines-of-code-weighting.sh"
source "$(dirname "$0")/calc-reaction-count-weighting.sh"
source "$(dirname "$0")/calc-reaction-speed-weighting.sh"

#--------------------------------------
# 出力先のファイルを作成する
#--------------------------------------
readonly WEIGHTED_DIR="${OUTPUT_DIR}/weighted-data"
readonly RESULT_WEIGHTED_PATH="${WEIGHTED_DIR}/result-weighted.json"
mkdir -p "$(dirname "$RESULT_WEIGHTED_PATH")"

#--------------------------------------
# 各種の評価軸で重み付けの値を受け取った後に合計して、一覧にする
#--------------------------------------
function calc_weighting() {
  calc_task_type_weighting
  calc_period_weighting
  calc_lines_of_code_weighting
  calc_reaction_count_weighting
  calc_reaction_speed_weighting
}
