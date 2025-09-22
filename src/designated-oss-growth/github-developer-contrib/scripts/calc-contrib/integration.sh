#!/bin/bash

#--------------------------------------
# 各種の評価軸で重み付けの値を受け取った後に貢献度を算出する処理を統合する
#--------------------------------------

set -euo pipefail

#--------------------------------------
# 出力先のディレクトリを作成する
#--------------------------------------
readonly OUTPUT_CALC_CONTRIB_DIR="${OUTPUT_DIR}/calc-contrib"
mkdir -p "$OUTPUT_CALC_CONTRIB_DIR"

#--------------------------------------
# 使用するファイルを読み込む
#--------------------------------------
readonly CALC_CONTRIB_DIR="${SCRIPT_DIR}/scripts/calc-contrib"
source "${CALC_CONTRIB_DIR}/calc-task-type-weighting.sh"
source "${CALC_CONTRIB_DIR}/calc-period-weighting.sh"
source "${CALC_CONTRIB_DIR}/calc-lines-of-code-weighting.sh"
source "${CALC_CONTRIB_DIR}/calc-reaction-count-weighting.sh"
source "${CALC_CONTRIB_DIR}/calc-reaction-speed-weighting.sh"
source "${CALC_CONTRIB_DIR}/calc-amount-contrib.sh"

#--------------------------------------
# 貢献度の算出の処理を統合する関数
#--------------------------------------
function calc_contrib() {
  # if should_run "star" "$@"; then calc_star; fi
  # if should_run "fork" "$@"; then calc_fork; fi
  # if should_run "repo-meta" "$@"; then calc_repo_meta; fi
  # if should_run "sponsor" "$@"; then calc_sponsor; fi
  # if should_run "watch" "$@"; then calc_watch; fi
  # if should_run "issue" "$@"; then calc_issue; fi
  # if should_run "pull-request" "$@"; then calc_pull_request; fi
  # if should_run "release" "$@"; then calc_release; fi
  # if should_run "commit" "$@"; then calc_commit; fi
  # if should_run "discussion" "$@"; then calc_discussion; fi

  calc_task_type_weighting
  calc_period_weighting
  calc_lines_of_code_weighting
  calc_reaction_count_weighting
  calc_reaction_speed_weighting
  calc_amount_contrib
}
