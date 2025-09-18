#!/usr/bin/env bash

#--------------------------------------
# データ加工の共通関数を定義するファイル
#--------------------------------------

set -euo pipefail

#--------------------------------------
# データ加工の共通関数を定義する
#--------------------------------------

function process_sponsor_data() {
  local INPUT_PATH="${1:-}"
  local OUTPUT_PATH="${2:-}"
  local TASK_NAME="${3:-}"
  local TASK_DATE="${4:-}"
  local NEST_KEY="${5:-}"

  jq \
    --arg task_name "$TASK_NAME" \
    --arg task_date "$TASK_DATE" \
    --arg nest_key "$NEST_KEY" \
    --arg task_date "$TASK_DATE" \
    '
  {
    data: {
      user:
        (
          [ .[]?
            | . as $repo
            | .($nest_key)? as $o
            | {
                user_id:          ($o | .id),
                user_database_id: ($o | .databaseId),
                user_login:       ($o | .login),
                user_name:        ($o | .name),
                user_url:
                  ( if (($o|type)=="object" and ($o|has("url")) and ($o.url!=null))
                    then $o.url
                    elif (($o|type)=="object" and ($o|has("login")) and ($o.login!=null))
                      then "https://github.com/\($o.login)"
                    else null end ),
                task: [
                  {
                    task_id:               ($repo | .id),
                    task_database_id:      ($repo | .databaseId),
                    task_full_database_id: ($repo | .fullDatabaseId),
                    task_name:             $task_name,
                    task_date:             ($repo | .($task_date)),
                    reference_task_date:   $task_date
                  }
                ]
              }
          ]
          | sort_by(.user_id)               # group_by の前にソート
          | group_by(.user_id)
          | map(
              (.[0] | {user_id, user_database_id, user_login, user_name, user_url})
              + { task: (map(.task) | add) } # 同一ユーザーの task を結合
            )
        )
    }
  }
    ' "$INPUT_PATH" \
    >"$OUTPUT_PATH"
}
