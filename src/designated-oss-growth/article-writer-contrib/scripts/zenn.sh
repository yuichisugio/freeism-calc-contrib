#!/bin/bash

# -------------------------------------
# zenn関連のデータ取得を行うファイル
#--------------------------------------

set -euo pipefail

#--------------------------------------
# 出力先のファイルを定義
#--------------------------------------
readonly OUTPUT_FILE="${OUTPUT_DIR}/zenn.json"

#--------------------------------------
# データ取得
#--------------------------------------
function get_zenn() {

  printf '%s\n' "begin:get_zenn()"

  # 変数
  local -a topicnames=()

  # 設定ファイルからtopicnameを取得
   mapfile -t topicnames < <(jq -r '.search_names[]' "$INPUT_CONFIG_PATH")

  # temp
  local tmp_response tmp_json
  tmp_response="$(mktemp)"
  tmp_json="$(mktemp)"
  trap 'rm -f "${tmp_response:-}" "${tmp_json:-}"' RETURN

  # topicnameに対して、APIを叩いてデータを取得
  for topicname in "${topicnames[@]}"; do

    local page=1

    while :; do
      # APIを叩いてデータを取得
      curl -fsS "https://zenn.dev/api/articles?topicname=${topicname}&order=latest&count=48&page=${page}" >"$tmp_response"

      # データを追加
      jq -r '.articles[]' "$tmp_response" >>"$tmp_json"

      # 続きがない、もしくは期間外の場合は終了
      if [[ "$(jq -r '.next_page' "$tmp_response")" == "null" ]]; then
        break
      fi

      # 次のページに進む
      page=$((page + 1))

    done

  done

  # 一時ファイルを元のファイルに移動
  mv -f "$tmp_json" "$OUTPUT_FILE"

  printf '%s\n' "end:get_zenn()"

  return 0
}
