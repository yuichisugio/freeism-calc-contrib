#!/bin/bash

#--------------------------------------
# pull requestの共通関数を定義するファイル
#--------------------------------------

set -euo pipefail

#--------------------------------------
# 手動ページネーションで、SINCEからUNTILの期間で絞ってJSONLに追記
#--------------------------------------
function get_paginated_repository_data() {

  # raw_pathは取得したままのデータ。resultはlocal側で、期間で絞ったデータ
  local QUERY="$1" RAW_PATH="$2" RESULT_PATH="$3"
  local HAS_NEXT_PAGE END_CURSOR LAST_DATE RESPONSE

  # 同じPATHに実行する場合に、前回の内容をファイルを空にする
  : >"$RAW_PATH"
  : >"$RESULT_PATH"

  # 手動ページネーションで、SINCEからUNTILの期間で絞ってJSONLに追記
  while :; do

    # OWNERとREPOはmain.shでグローバル変数として定義されている
    gh api graphql \
      --header X-Github-Next-Global-ID:1 \
      -f owner="$OWNER" \
      -f name="$REPO" \
      -F endCursor="${END_CURSOR:-null}" \
      -F perPage=50 \
      -f query="$QUERY" |
      jq '.' >>"$RAW_PATH"

    # 期間で絞ってJSONLに追記
    # SINCEとUNTILはmain.shでグローバル変数として定義されている
    jq -r --arg SINCE "$SINCE" --arg UNTIL "$UNTIL" '
      .data.repository.pullRequests.nodes[]
      | select(.publishedAt >= $SINCE and .publishedAt <= $UNTIL)
    ' "$RAW_PATH" >>"$RESULT_PATH"

    # 次ページの準備
    HAS_NEXT_PAGE="$(jq -r '.data.repository.pullRequests.pageInfo.hasNextPage' "$RAW_PATH")"
    END_CURSOR="$(jq -r '.data.repository.pullRequests.pageInfo.endCursor' "$RAW_PATH")"
    LAST_DATE="$(jq -r '(.data.repository.pullRequests.nodes | last | .publishedAt) // empty' "$RAW_PATH")"

    # 続きがない、もしくは期間外の場合は終了
    if [[ "$HAS_NEXT_PAGE" != "true" || "$END_CURSOR" == "null" || -z "$END_CURSOR" || (-n "$LAST_DATE" && "$LAST_DATE" > "$UNTIL") ]]; then
      break
    fi
  done
}

#--------------------------------------
# 手動ページネーションで、node_id・SINCEからUNTILの期間で絞ってJSONLに追記
#--------------------------------------
function get_paginated_data_by_node_id() {

  # raw_pathは取得したままのデータ。resultはlocal側で、期間で絞ったデータ
  local QUERY="$1" RAW_PATH="$2" RESULT_PATH="$3" FIRST_CHECK_FIELD_NAME="$4" SECOND_CHECK_FIELD_NAME="$5"
  local HAS_NEXT_PAGE END_CURSOR LAST_DATE RESPONSE

  # 同じPATHに実行する場合に、前回の内容をファイルを空にする
  : >"$RAW_PATH"
  : >"$RESULT_PATH"

  # 手動ページネーションで、SINCEからUNTILの期間で絞ってJSONLに追記
  while :; do

    # OWNERとREPOはmain.shでグローバル変数として定義されている
    gh api graphql \
      --header X-Github-Next-Global-ID:1 \
      -f node_id="$NODE_ID" \
      -F endCursor="${END_CURSOR:-null}" \
      -F perPage=50 \
      -f query="$QUERY" |
      jq '.' >>"$RAW_PATH"

    # 期間で絞ってJSONLに追記
    # SINCEとUNTILはmain.shでグローバル変数として定義されている
    jq -r \
      --arg SINCE "$SINCE" \
      --arg UNTIL "$UNTIL" \
      --arg FIRST_CHECK_FIELD_NAME "$FIRST_CHECK_FIELD_NAME" \
      --arg SECOND_CHECK_FIELD_NAME "$SECOND_CHECK_FIELD_NAME" \
      '
      .data.node.${FIRST_CHECK_FIELD_NAME}.nodes[]
      | select(.${SECOND_CHECK_FIELD_NAME} >= $SINCE and .${SECOND_CHECK_FIELD_NAME} <= $UNTIL)
    ' "$RAW_PATH" >>"$RESULT_PATH"

    # 次ページの準備
    HAS_NEXT_PAGE="$(jq -r '.data.repository.pullRequests.pageInfo.hasNextPage' "$RAW_PATH")"
    END_CURSOR="$(jq -r '.data.repository.pullRequests.pageInfo.endCursor' "$RAW_PATH")"
    LAST_DATE="$(
      jq -r \
        --arg FIRST_CHECK_FIELD_NAME "$FIRST_CHECK_FIELD_NAME" \
        --arg SECOND_CHECK_FIELD_NAME "$SECOND_CHECK_FIELD_NAME" \
        '(.data.node.${FIRST_CHECK_FIELD_NAME}.nodes | last | .${SECOND_CHECK_FIELD_NAME}) // empty' "$RAW_PATH"
    )"

    # 続きがない、もしくは期間外の場合は終了
    if [[ "$HAS_NEXT_PAGE" != "true" || "$END_CURSOR" == "null" || -z "$END_CURSOR" || (-n "$LAST_DATE" && "$LAST_DATE" > "$UNTIL") ]]; then
      break
    fi
  done
}

#--------------------------------------
# 手動ページネーションで、SINCEからUNTILの期間で絞ってJSONLに追記
#--------------------------------------
function get_paginated_timeline_data() {

  # raw_pathは取得したままのデータ。resultはlocal側で、期間で絞ったデータ
  local QUERY="$1" RAW_PATH="$2" RESULT_PATH="$3" IS_REPOSITORY="$4" IS_TIMELINE="$5"
  local HAS_NEXT_END_CURSOR RESPONSE

  while :; do

    if [[ "$IS_REPOSITORY" == "true" ]]; then
      gh api graphql \
        -f owner="$OWNER" \
        -f name="$REPO" \
        -f query="$QUERY" |
        jq '.' >>"$RAW_PATH"
    elif [[ "$IS_TIMELINE" == "true" ]]; then
      gh api graphql \
        -f node_id="$NODE_ID" \
        -f since="$SINCE" \
        -f query="$QUERY" |
        jq '.' >>"$RAW_PATH"
    else
      gh api graphql \
        -f node_id="$NODE_ID" \
        -f query="$QUERY" |
        jq '.' >>"$RAW_PATH"
    fi

    # 期間で絞ってJSONLに追記
    jq -r --arg START "$START" --arg END "$END" '
      .data.repository.stargazers.edges[]
      | select(.starredAt >= $START and .starredAt <= $END)
    ' "$RAW_STAR_PER_PAGE_JSON" >>"$RAW_STAR_JSONL_PATH"

    # 次ページの準備
    HAS_NEXT="$(jq -r '.data.repository.stargazers.pageInfo.hasNextPage' "$RAW_STAR_PER_PAGE_JSON")"
    CURSOR="$(jq -r '.data.repository.stargazers.pageInfo.endCursor' "$RAW_STAR_PER_PAGE_JSON")"
    LAST_DATE="$(jq -r '(.data.repository.stargazers.edges | last | .starredAt) // empty' "$RAW_STAR_PER_PAGE_JSON")"

    # 続きがない、もしくは期間外の場合は終了
    if [[ "$HAS_NEXT" != "true" || "$CURSOR" == "null" || -z "$CURSOR" ]] || [[ -n "$LAST_DATE" && "$LAST_DATE" > "$END" ]]; then
      break
    fi
  done

  # 最後に配列化して成果物（※入力と出力は別ファイルにする！）
  jq -s '.' "$RAW_PULL_REQUEST_JSONL_PATH" >"$RESULTS_PULL_REQUEST_JSON_PATH"

  gh api graphql \
    --paginate --slurp \
    --header X-Github-Next-Global-ID:1 \
    -f owner="$OWNER" \
    -f name="$REPO" \
    -F perPage=50 \
    -f query="$QUERY" | jq '.' >"$RESULTS_PULL_REQUEST_JSON_PATH"
}
