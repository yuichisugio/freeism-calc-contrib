#!/bin/bash

#--------------------------------------
# 共通関数を定義するファイル
#--------------------------------------

set -euo pipefail

#--------------------------------------
# Print to stderr
#--------------------------------------
function log() {
  printf '%s\n' "$*" >&2
}

#--------------------------------------
# Require tools
#--------------------------------------
function require_tools() {
  # 依存コマンドの確認
  for cmd in gh jq; do
    if ! command -v "$cmd" >/dev/null; then
      log "ERROR: $cmd が必要です。" >&2
      exit 1
    fi
  done

  # gh 認証確認
  if ! gh auth status >/dev/null; then
    log "ERROR: gh が認証されていません。" >&2
    exit 1
  fi

  return 0
}

#--------------------------------------
# Parse GitHub URL or repo identifier
# Examples:
# - https://github.com/OWNER/REPO(.git)?
# - git@github.com:OWNER/REPO(.git)?
# return: OWNER REPO
#--------------------------------------
function parse_github_url_args() {
  # 引数の値
  local input="${1:-}"
  # 引数の値が空の場合
  if [[ -z "$input" ]]; then
    log "parse_github_url_args: empty input"
    return 1
  fi
  # リポジトリのオーナー名とリポジトリ名を格納する変数
  local owner repo
  case "$input" in
  # http*://github.com/* の場合。クエリパラメータやフラグメントが含まれていても抽出しない対応あり
  http*://github.com/*)
    owner="$(printf '%s' "$input" | sed -E 's#https?://github.com/([^/]+)/([^/?#.]+).*#\1#')"
    repo="$(printf '%s' "$input" | sed -E 's#https?://github.com/([^/]+)/([^/?#.]+).*#\2#')"
    ;;
  # git@github.com:* の場合。.git がある場合も抽出しない対応`'..*`。
  git@github.com:*)
    owner="$(printf '%s' "$input" | sed -E 's#git@github.com:([^/]+)/([^/.]+)(\..*)?#\1#')"
    repo="$(printf '%s' "$input" | sed -E 's#git@github.com:([^/]+)/([^/.]+)(\..*)?#\2#')"
    ;;
  # owner/repo の場合
  */*)
    owner="${input%%/*}"
    repo="${input##*/}"
    ;;
  # それ以外の場合
  *)
    log "Unsupported repo format: $input"
    return 1
    ;;
  esac
  # リポジトリのオーナー名とリポジトリ名を返す
  printf '%s %s\n' "$owner" "$repo"
  return 0
}

#--------------------------------------
# Get default branch quickly via GraphQL
#--------------------------------------
function get_default_branch() {
  # 引数の値
  local owner="$1" repo="$2" default_branch

  # デフォルトブランチを取得
  # shellcheck disable=SC2016
  default_branch="$(gh api graphql -f query='
    query($owner: String!, $name: String!) {
      repository(owner: $owner, name: $name) {
        defaultBranchRef {
          name
        }
      }
    }
  ' \
    -f owner="$owner" \
    -f name="$repo" \
    --jq '.data.repository.defaultBranchRef.name')"

  # デフォルトブランチを返す
  printf '%s\n' "$default_branch"
  return 0
}

#--------------------------------------
# Simple REST paginator that emits one JSON object per line
#--------------------------------------
function rest_paginate_jq() {
  # 引数の値。path starting with /
  local endpoint="$1"
  # shiftコマンドは位置パラメータを左にシフトする機能です。これにより、$2が$1に、$3が$2になります。
  shift || true
  # 受け取ったendpointと他の引数を渡す。JSON Lines で出力。"$@": 残りの全ての引数を展開する特殊変数
  gh api --paginate -H "Accept: application/vnd.github+json" "$endpoint" "$@" |
    jq -c '.[]'
}

#--------------------------------------
# Iterate cursor-based GraphQL connection and emit nodes as JSON Lines
# Args: query owner repo root_path connection_path
# - query: GraphQL string using $owner, $name, $cursor
# - root_path: jq path to connection root (e.g., ".data.repository.pullRequests")
# - connection_path: ".nodes[]" (default) or arbitrary jq to emit per node
#--------------------------------------
function gql_paginate_nodes() {
  # 引数の値
  local query="$1" owner="$2" name="$3" root_path="$4" connection_nodes="${5:-.nodes[]}"
  # カーソルを格納する変数
  local cursor="" has_next=true

  # 次の値がある場合は繰り返す
  while $has_next; do

    # レスポンスを格納する変数
    local response

    # カーソルがある場合はカーソルを渡す。
    if [[ -n "$cursor" ]]; then
      response="$(gh api graphql -f query="$query" -F owner="$owner" -F name="$name" -F cursor="$cursor")"
    else
      response="$(gh api graphql -f query="$query" -F owner="$owner" -F name="$name")"
    fi

    # ヒアストリング（<<<）を使用して、レスポンスデータをjqに渡す。JSON Lines で出力。
    jq -c "${root_path} | ${connection_nodes}" <<<"$response"

    # 次の値があるかどうかを格納する変数
    has_next=$(jq -r "${root_path}.pageInfo.hasNextPage" <<<"$response")

    # 次の値がある場合はカーソルを格納する
    if [[ "$has_next" == "true" ]]; then
      cursor=$(jq -r "${root_path}.pageInfo.endCursor" <<<"$response")
    else
      has_next=false
    fi
  done
}

#--------------------------------------
# 使い方の表示
#--------------------------------------
function show_usage() {
  cat <<EOF
    Usage: $0 [GITHUB_URL]

    GitHub リポジトリのプルリクエスト貢献者を分析し、
    各ユーザーの貢献度をCSV形式で出力します。

    Parameters:
      GITHUB_URL    リポジトリのURL (デフォルト: https://github.com/ryoppippi/ccusage)

    Output:
      userId,username,pullrequest回数

    Examples:
      $0 https://github.com/ryoppippi/ccusage     # ryoppippi/ccusage を分析
      $0 https://github.com/microsoft/vscode   # microsoft/vscode を分析
EOF

  return 0
}

#--------------------------------------
# 出力ディレクトリの準備
#--------------------------------------
function setup_output_directory() {
  # 引数の値
  local owner="$1" repo="$2" RESULTS_DIR RAW_DATA_DIR

  # 結果ディレクトリの準備
  RESULTS_DIR="./results/${owner}/${repo}"
  RAW_DATA_DIR="${RESULTS_DIR}/raw-data"

  # 結果ディレクトリの準備
  if [[ ! -d "$RESULTS_DIR" ]]; then
    mkdir -p "$RESULTS_DIR"
  fi

  # 生データディレクトリの準備
  if [[ ! -d "$RAW_DATA_DIR" ]]; then
    mkdir -p "$RAW_DATA_DIR"
  fi

  return 0
}
