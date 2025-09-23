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
  local INPUT_PATH OUTPUT_PATH TASK_NAME TASK_DATE AUTHOR_FIELD
  # 未設定参照を防ぐため空で初期化
  local FIRST_OTHER_QUERY="" SECOND_OTHER_QUERY=""

  # 変数
  local MAIN_QUERY JQ_PROGRAM
  local FIRST_EXTRA_MERGE SECOND_EXTRA_MERGE

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
            __FIRST_EXTRA_MERGE__
            | {
                user_type:        ($author.__typename // $author_field),
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
                    } __SECOND_EXTRA_MERGE__
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
  # ${変数名//パターン/置換文字}の形式で、変数の中の空白を削除しても変数内にデータがあるか確認
  if [[ -n "${FIRST_OTHER_QUERY//[$'\t\r\n ']/}" ]]; then
    # OTHER_QUERY が空でない場合は、EXTRA_MERGE に追加
    FIRST_EXTRA_MERGE="${FIRST_OTHER_QUERY}"
  else
    # OTHER_QUERY が空の場合は、デフォのフィルターを追加
    # shellcheck disable=SC2016
    FIRST_EXTRA_MERGE='
      {
        data: {
          user: (
            [ .[]?
              | . as $obj
              | .[$author_field] as $author
    '

  fi

  # 2か所目。オブジェクトをマージしたいので、+ ({}) でマージする
  if [[ -n "${SECOND_OTHER_QUERY//[$'\t\r\n ']/}" ]]; then
    SECOND_EXTRA_MERGE="| . + { ${SECOND_OTHER_QUERY} }"
  else
    SECOND_EXTRA_MERGE=''
  fi

  # プレースホルダを差し替えて、JQ_PROGRAM を作成
  JQ_PROGRAM="${MAIN_QUERY/__FIRST_EXTRA_MERGE__/${FIRST_EXTRA_MERGE}}"
  JQ_PROGRAM="${JQ_PROGRAM/__SECOND_EXTRA_MERGE__/${SECOND_EXTRA_MERGE}}"

  # 実行して、OUTPUT_PATH に出力
  jq \
    --arg task_name "$TASK_NAME" \
    --arg task_date "$TASK_DATE" \
    --arg author_field "$AUTHOR_FIELD" \
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
