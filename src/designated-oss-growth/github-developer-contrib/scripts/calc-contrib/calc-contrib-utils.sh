#!/usr/bin/env bash

#--------------------------------------
# 貢献度の算出の共通関数を定義するファイル
#--------------------------------------

set -euo pipefail

#--------------------------------------
# 貢献度の算出の共通関数を定義する
#--------------------------------------
function calc_contrib_utils() {

  # 引数
  local INPUT_PATH OUTPUT_PATH TASK_NAME RESPONSE_SPEED AMOUNT_OF_WORK AMOUNT_OF_REACTION STATUS REPO_CREATION_TO_TASK_PERIOD FIRST_OTHER_QUERY SECOND_OTHER_QUERY

  # 変数
  local MAIN_QUERY JQ_PROGRAM

  # 引数を解析
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --input-path)
      INPUT_PATH="$2"
      shift 2
      ;;
    --output-path)
      OUTPUT_PATH="$2"
      shift 2
      ;;
    --task-name)
      TASK_NAME="$2"
      shift 2
      ;;
    --response-speed)
      RESPONSE_SPEED="$2"
      shift 2
      ;;
    --amount-of-work)
      AMOUNT_OF_WORK="$2"
      shift 2
      ;;
    --amount-of-reaction)
      AMOUNT_OF_REACTION="$2"
      shift 2
      ;;
    --status)
      STATUS="$2"
      shift 2
      ;;
    --repo_creation_to_task_period)
      REPO_CREATION_TO_TASK_PERIOD="$2"
      shift 2
      ;;
    --first-other-query)
      FIRST_OTHER_QUERY="$2"
      shift 2
      ;;
    --second-other-query)
      SECOND_OTHER_QUERY="$2"
      shift 2
      ;;
    *)
      printf '%s\n' "Unknown option: $1" >&2
      exit 1
      ;;
    esac
  done

  # メインの jq フィルタ（__EXTRA_MERGE__ を後で置換する）
  # shellcheck disable=SC2016
  MAIN_QUERY='
    __RESPONSE_SPEED__
    __AMOUNT_OF_WORK__
    __AMOUNT_OF_REACTION__
    __STATUS__
    __REPO_CREATION_TO_TASK_PERIOD__
    __FIRST_OTHER_QUERY__
    __SECOND_OTHER_QUERY__
  '

  # shellcheck disable=SC2016
  RESPONSE_SPEED_QUERY='{
    "criterion_weight_for_response_speed": $rs
  }'
  # shellcheck disable=SC2016
  AMOUNT_OF_WORK_QUERY='{
    "criterion_weight_for_amount_of_work": $aow
  }'
  # shellcheck disable=SC2016
  AMOUNT_OF_REACTION_QUERY='{
    "criterion_weight_for_amount_of_reaction": $aor
  }'
  # shellcheck disable=SC2016
  STATUS_QUERY='{
    "criterion_weight_for_status": $status
  }'
  # shellcheck disable=SC2016
  REPO_CREATION_TO_TASK_PERIOD_QUERY='{
    "criterion_weight_for_repo_creation_to_task_period": $rcttp
  }'
  # shellcheck disable=SC2016
  FIRST_OTHER_QUERY='{
    "criterion_weight_for_first_other_query": $first_other_query
  }'
  # shellcheck disable=SC2016
  SECOND_OTHER_QUERY='{
    "criterion_weight_for_second_other_query": $second_other_query
  }'
  # RESPONSE_SPEEDがtrueの場合
  if [[ "${RESPONSE_SPEED}" == "true" ]]; then
    __RESPONSE_SPEED__="${RESPONSE_SPEED_QUERY}"
  else
    __RESPONSE_SPEED__=''
  fi

  # AMOUNT_OF_WORKがtrueの場合
  if [[ "${AMOUNT_OF_WORK}" == "true" ]]; then
    __AMOUNT_OF_WORK__="${AMOUNT_OF_WORK_QUERY}"
  else
    __AMOUNT_OF_WORK__=''
  fi

  # AMOUNT_OF_REACTIONがtrueの場合
  if [[ "${AMOUNT_OF_REACTION}" == "true" ]]; then
    __AMOUNT_OF_REACTION__="${AMOUNT_OF_REACTION_QUERY}"
  else
    __AMOUNT_OF_REACTION__=''
  fi

  if [[ "${STATUS}" == "true" ]]; then
    __STATUS__="${STATUS_QUERY}"
  else
    __STATUS__=''
  fi

  if [[ "${REPO_CREATION_TO_TASK_PERIOD}" == "true" ]]; then
    __REPO_CREATION_TO_TASK_PERIOD__="${REPO_CREATION_TO_TASK_PERIOD_QUERY}"
  else
    __REPO_CREATION_TO_TASK_PERIOD__=''
  fi

  if [[ "${FIRST_OTHER_QUERY}" == "true" ]]; then
    __FIRST_OTHER_QUERY__="${FIRST_OTHER_QUERY}"
  else
    __FIRST_OTHER_QUERY__=''
  fi

  if [[ "${SECOND_OTHER_QUERY}" == "true" ]]; then
    __SECOND_OTHER_QUERY__="${SECOND_OTHER_QUERY}"
  else
    __SECOND_OTHER_QUERY__=''
  fi

  # プレースホルダを差し替えて、JQ_PROGRAM を作成
  JQ_PROGRAM="${MAIN_QUERY/__RESPONSE_SPEED__/${RESPONSE_SPEED_QUERY}}"
  JQ_PROGRAM="${JQ_PROGRAM/__AMOUNT_OF_WORK__/${AMOUNT_OF_WORK_QUERY}}"
  JQ_PROGRAM="${JQ_PROGRAM/__AMOUNT_OF_REACTION__/${AMOUNT_OF_REACTION_QUERY}}"
  JQ_PROGRAM="${JQ_PROGRAM/__STATUS__/${STATUS_QUERY}}"
  JQ_PROGRAM="${JQ_PROGRAM/__REPO_CREATION_TO_TASK_PERIOD__/${REPO_CREATION_TO_TASK_PERIOD_QUERY}}"

  # 実行して、OUTPUT_PATH に出力
  jq \
    --arg task_name "$TASK_NAME" \
    --arg response_speed "$RESPONSE_SPEED" \
    --arg amount_of_work "$AMOUNT_OF_WORK" \
    --arg amount_of_reaction "$AMOUNT_OF_REACTION" \
    --arg status "$STATUS" \
    --arg repo_creation_to_task_period "$REPO_CREATION_TO_TASK_PERIOD" \
    --arg first_other_query "$FIRST_OTHER_QUERY" \
    --arg second_other_query "$SECOND_OTHER_QUERY" \
    "$JQ_PROGRAM" \
    "$INPUT_PATH" >"$OUTPUT_PATH"
}

#--------------------------------------
# 算出した貢献度から、タスクを抜いたバージョンを作成する
#--------------------------------------
function exclude_task() {

  # 引数
  local OUTPUT_PATH INPUT_PATH

  # 引数を解析
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --input-path)
      INPUT_PATH="$2"
      shift 2
      ;;
    --output-path)
      OUTPUT_PATH="$2"
      shift 2
      ;;
    *)
      printf '%s\n' "Unknown option: $1" >&2
      exit 1
      ;;
    esac
  done

  jq \
    '
      .data.user[]?.task = []
    ' \
    "$INPUT_PATH" \
    >"$OUTPUT_PATH"
}
