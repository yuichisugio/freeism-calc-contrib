#!/usr/bin/env bash

#--------------------------------------
# データ加工の共通関数を定義するファイル
#--------------------------------------

set -euo pipefail

#--------------------------------------
# データ加工の共通関数を定義する
#--------------------------------------
function process_data_utils() {

  # 引数
  local INPUT_PATH OUTPUT_PATH TASK_NAME TASK_DATE AUTHOR_FIELD OTHER_QUERY

  # 変数
  local MAIN_QUERY JQ_PROGRAM EXTRA_MERGE

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
    --task-date)
      TASK_DATE="$2"
      shift 2
      ;;
    --author-field)
      AUTHOR_FIELD="$2"
      shift 2
      ;;
    --other-query)
      OTHER_QUERY="$2"
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
    {
      data: {
        user: (
          [ .[]?
            | . as $obj
            | .[$author_field] as $author
            | {
                user_type:        $author.__typename,
                user_id:          $author.id,
                user_database_id: $author.databaseId,
                user_login:       $author.login,
                user_name:        $author.name,
                user_url:         $author.url,
                task: [
                  (
                    {
                      task_id:               $obj.id,
                      task_database_id:      $obj.databaseId,
                      task_full_database_id: $obj.fullDatabaseId,
                      task_url:              $obj.url,
                      task_name:             $task_name,
                      task_date:             $obj[$task_date],
                      reference_task_date_field: $task_date
                    } __EXTRA_MERGE__
                  )
                ]
              }
          ]
          | group_by(.user_id)
          | map(
              (
                .[0] 
                | {
                    user_id, 
                    user_database_id, 
                    user_login, 
                    user_name, 
                    user_url, 
                    user_type
                  }
              )
              + { task: (map(.task) | add) }
            )
        )
      }
    }
  '

  # OTHER_QUERY が空でない場合は、EXTRA_MERGE に追加
  if [[ -n "${OTHER_QUERY//[$'\t\r\n ']/}" ]]; then
    EXTRA_MERGE="+ ({${OTHER_QUERY}})"
  else
    EXTRA_MERGE=''
  fi

  # プレースホルダを差し替えて、JQ_PROGRAM を作成
  JQ_PROGRAM="${MAIN_QUERY/__EXTRA_MERGE__/$EXTRA_MERGE}"

  # 実行して、OUTPUT_PATH に出力
  jq \
    --arg task_name "$TASK_NAME" \
    --arg task_date "$TASK_DATE" \
    --arg author_field "$AUTHOR_FIELD" \
    "$JQ_PROGRAM" \
    "$INPUT_PATH" >"$OUTPUT_PATH"
}
