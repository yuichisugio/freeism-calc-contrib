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
      user: (
        [ .[]?
          | . as $obj
          | .author as $author
          | {
              user_type:        $author.__typename,
              user_id:          $author.id,
              user_database_id: $author.databaseId,
              user_login:       $author.login,
              user_name:        $author.name,
              user_url:         $author.url,
              task: [
                {
                  task_id:               $obj.id,
                  task_database_id:      $obj.databaseId,
                  task_full_database_id: $obj.fullDatabaseId,
                  task_url:              $obj.url,
                  task_name:             "comment",
                  task_date:             $obj.publishedAt,
                  reference_task_date_field: "publishedAt",
                  commit_word_count:     ($obj.bodyText? // "" | length),

                  # content == "THUMBS_DOWN" だけを bad、それ以外は good
                  good_reaction:
                    (
                      ( $obj.reactionGroups? // [] )
                      | map(
                        if (.content // "") == "THUMBS_DOWN"
                          then 0
                          else (.reactors.totalCount // 0)
                          end
                        )
                      | add // 0
                    ),

                  bad_reaction:
                    (
                      ( $obj.reactionGroups? // [] )
                      | map(
                          if (.content // "") == "THUMBS_DOWN"
                          then (.reactors.totalCount // 0)
                          else 0
                          end
                        )
                      | add // 0
                    )
                }
              ]
            }
        ]
        | sort_by(.user_id)
        | group_by(.user_id)
        | map(
            (.[0] | {user_id, user_database_id, user_login, user_name, user_url} )
            + { task: (map(.task) | add) }   # 同一ユーザーの task を結合
          )
      )
    }
  }
    ' "$INPUT_PATH" \
    >"$OUTPUT_PATH"
}
