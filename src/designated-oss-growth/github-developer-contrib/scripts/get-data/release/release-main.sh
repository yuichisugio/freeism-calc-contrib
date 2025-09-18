#!/bin/bash

#--------------------------------------
# リリースのデータ取得を統合するファイル
#--------------------------------------

set -euo pipefail

#--------------------------------------
# 出力先のファイルを定義
#--------------------------------------
readonly RESULT_GET_RELEASE_DIR="${OUTPUT_GET_DIR}/release"
mkdir -p "$RESULT_GET_RELEASE_DIR"
readonly RESULT_RELEASE_NODE_ID_PATH="${RESULT_GET_RELEASE_DIR}/result-release-node-id.json"

#--------------------------------------
# 使用するファイルを読み込む
#--------------------------------------
source "${GET_DIR}/release/release-node-id.sh"
source "${GET_DIR}/release/release-reaction.sh"

#--------------------------------------
# リリースのデータを取得する関数
#--------------------------------------
function get_release() {

  local before_remaining_ratelimit

  # データ取得前のRateLimitを取得
  before_remaining_ratelimit="$(get_ratelimit "before:get-release()")"

  # リリースのnode_idと各種フィールドのtotalCountを取得
  get_release_node_id

  # リリースのリアクションを取得
  get_release_reaction

  # データ取得後のRateLimitを出力
  get_ratelimit \
    "after:get-release()" \
    "$before_remaining_ratelimit" \
    "false"
}
