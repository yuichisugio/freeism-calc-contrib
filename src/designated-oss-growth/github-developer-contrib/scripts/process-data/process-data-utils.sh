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
  local INPUT_PATH OUTPUT_PATH TASK_NAME TASK_DATE AUTHOR_FIELD OTHER_QUERY_PATH

  # 変数
  local QUERY JQ_FILTER_FILE=() JQ_PROGRAM

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
    --other-query-path)
      OTHER_QUERY_PATH="$2"
      shift 2
      ;;
    *)
      printf '%s\n' "Unknown option: $1" >&2
      exit 1
      ;;
    esac
  done

  # メインの jq カスタムクエリ
  # shellcheck disable=SC2016
  QUERY='
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
                    }
                    + (try extra($obj) catch {})
                  )
                ]
              }
          ]
          | sort_by(.user_id)
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

  # extra() の与え方を分岐
  if [[ -n "${OTHER_QUERY_PATH:-}" ]]; then
    # 呼び出し元が用意した jq ファイルから extra() をロード
    JQ_FILTER_FILE=(-f "$OTHER_QUERY_PATH")
    JQ_PROGRAM="$QUERY"
  else
    # extra() が無い場合はダミーをメインクエリに前置
    # $'\n' を使って1引数の文字列として渡す
    JQ_PROGRAM=$'def extra($obj): {};\n'"$QUERY"
  fi

  # 実行（-n は付けない：入力ファイルを読むため）
  jq \
    --arg task_name "$TASK_NAME" \
    --arg task_date "$TASK_DATE" \
    --arg author_field "$AUTHOR_FIELD" \
    "${JQ_FILTER_FILE[@]}" \
    "$JQ_PROGRAM" \
    "$INPUT_PATH" >"$OUTPUT_PATH"
}
