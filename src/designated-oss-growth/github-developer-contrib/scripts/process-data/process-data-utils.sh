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
    SECOND_EXTRA_MERGE="+ ({${SECOND_OTHER_QUERY}})"
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
# データ加工の共通関数を定義する
#--------------------------------------
function process_data_utils_by_two_files() {

  # 引数
  local INPUT_NOW_PATH INPUT_TIMELINE_PATH OUTPUT_PATH TASK_NAME TASK_DATE EVENT_TYPE NEST_EVENT_FIELD

  # 変数
  local MAIN_QUERY

  # 引数を解析
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --input-now-path)
      INPUT_NOW_PATH="$2"
      shift 2
      ;;
    --input-timeline-path)
      INPUT_TIMELINE_PATH="$2"
      shift 2
      ;;
    --output-path)
      OUTPUT_PATH="$2"
      shift 2
      ;;
    --event-type)
      EVENT_TYPE="$2"
      shift 2
      ;;
    --nest-event-field)
      NEST_EVENT_FIELD="$2"
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
    *)
      printf '%s\n' "Unknown option: $1" >&2
      exit 1
      ;;
    esac
  done

  # メインの jq フィルタ（__EXTRA_MERGE__ を後で置換する）
  # shellcheck disable=SC2016
  MAIN_QUERY='
    # 現在の一覧
    ($now[0] // []) as $now_objects
    | (
        $now_objects
        | group_by(.node_id)
        | map({ (.[0].node_id): (map(.id) | unique) })
        | add
      ) as $by_object

    # タイムライン配列を処理
    |
    {
      data: {
        user: (
          [
            (
              # まず「オブジェクトのみ」を対象にする（配列等を除外）
              [ .[]? | select((.__typename? // "") == $event_type) ]

              # $event_type のみ残す
              | map(
                  . as $e
                  | select(
                      ($e.node_id? and $e[$nest_event_field]?.id?)
                      and (
                        ($by_object[$e.node_id] // []) 
                        | index($e[$nest_event_field].id) != null
                      )
                  )
                )

              # issue × $nest_event_field ごとに「最後の設定イベント」だけ残す
              | sort_by([.node_id, .[$nest_event_field].id, (.createdAt | fromdateiso8601)])
              | group_by([.node_id, .[$nest_event_field].id])
              | map( max_by(.createdAt | fromdateiso8601) )
              | .[]
            )
            | . as $obj
            | .actor as $author
            | {
                user_type:                      $author.__typename,
                user_id:                        $author.id,
                user_database_id:               $author.databaseId,
                user_login:                     $author.login,
                user_name:                      $author.name,
                user_url:                       $author.url,
                task: [
                  {
                    task_id:                    $obj.id,
                    task_database_id:           ($obj.databaseId // null),
                    task_full_database_id:      ($obj.fullDatabaseId // null),
                    task_url:                   ($obj.url // null),
                    task_name:                  $task_name,
                    task_date:                  $obj[$task_date],
                    reference_task_date_field:  $task_date,
                    node_url:                   $obj.node_url,
                    ($nest_event_field + "_id"):$obj[$nest_event_field].id,
                    ($nest_event_field + "_database_id"):$obj[$nest_event_field].databaseId,
                    ($nest_event_field + "___typename"):$obj[$nest_event_field].__typename,
                    ($nest_event_field + "_name"): $obj[$nest_event_field].name,
                    ($nest_event_field + "_login"): $obj[$nest_event_field].login,
                    ($nest_event_field + "_url"):  ($obj[$nest_event_field].url // null)
                  }
                ]
              }
          ]
          # 同一ユーザーの task を結合
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

  # 実行して、OUTPUT_PATH に出力
  jq \
    --slurpfile now "$INPUT_NOW_PATH" \
    --arg event_type "$EVENT_TYPE" \
    --arg nest_event_field "$NEST_EVENT_FIELD" \
    --arg task_name "$TASK_NAME" \
    --arg task_date "$TASK_DATE" \
    "$MAIN_QUERY" \
    "$INPUT_TIMELINE_PATH" \
    >"$OUTPUT_PATH"
}
