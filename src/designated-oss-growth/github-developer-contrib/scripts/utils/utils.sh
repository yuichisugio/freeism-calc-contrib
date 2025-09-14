#!/bin/bash

#--------------------------------------
# 共通関数を定義するファイル
#--------------------------------------

set -euo pipefail

#--------------------------------------
# Require tools
#--------------------------------------
function require_tools() {
  # 依存コマンドの確認
  for cmd in gh jq; do
    if ! command -v "$cmd" >/dev/null; then
      printf '%s\n' "ERROR: $cmd not found" >&2
      exit 1
    fi
  done

  # gh 認証確認
  if ! gh auth status >/dev/null; then
    printf '%s\n' "ERROR: gh not authenticated" >&2
    exit 1
  fi

  return 0
}

#--------------------------------------
# Parse GitHub URL or repo identifier
# Examples:
# - https://github.com/OWNER/REPO(.git)?
# - git@github.com:OWNER/REPO(.git)?
# return: OWNER REPO SINCE UNTIL
#--------------------------------------
function parse_args() {
  # 引数の値
  local URL="https://github.com/ryoppippi/ccusage"
  local OWNER="ryoppippi"
  local REPO="ccusage"
  local SINCE="1970-01-01"
  local UNTIL
  UNTIL="$(date -u +%Y-%m-%dT23:59:59Z)"

  # --- 引数パース。引数がある場合はデフォルト値を上書きする ---
  while [[ $# -gt 0 ]]; do
    case "$1" in
    -u | --url)
      URL="$2"
      shift 2
      ;;
    -s | --since)
      SINCE="$2"
      shift 2
      ;;
    -un | --until)
      UNTIL="$2"
      shift 2
      ;;
    -h | --help)
      show_usage
      exit 1
      ;;
    *)
      printf '%s\n' "Unknown option: $1" >&2
      show_usage
      exit 1
      ;;
    esac
  done

  # ISO 8601 に正規化
  [[ "$SINCE" == *T* ]] || SINCE="${SINCE}T00:00:00Z"
  [[ "$UNTIL" == *T* ]] || UNTIL="${UNTIL}T23:59:59Z"

  # リポジトリのオーナー名とリポジトリ名を格納する変数
  case "$URL" in
  # http*://github.com/* の場合。クエリパラメータやフラグメントが含まれていても抽出しない対応あり
  http*://github.com/*)
    OWNER="$(printf '%s' "$URL" | sed -E 's#https?://github.com/([^/]+)/([^/?#.]+).*#\1#')"
    REPO="$(printf '%s' "$URL" | sed -E 's#https?://github.com/([^/]+)/([^/?#.]+).*#\2#')"
    ;;
  # git@github.com:* の場合。.git がある場合も抽出しない対応`'..*`。
  git@github.com:*)
    OWNER="$(printf '%s' "$URL" | sed -E 's#git@github.com:([^/]+)/([^/.]+)(\..*)?#\1#')"
    REPO="$(printf '%s' "$URL" | sed -E 's#git@github.com:([^/]+)/([^/.]+)(\..*)?#\2#')"
    ;;
  # owner/repo の場合
  */*)
    OWNER="${URL%%/*}"
    REPO="${URL##*/}"
    ;;
  # それ以外の場合
  *)
    printf '%s\n' "Unsupported repo format: $URL" >&2
    return 1
    ;;
  esac
  # リポジトリのオーナー名とリポジトリ名を返す
  printf '%s %s %s %sの貢献度を算出します。\n' "$OWNER" "$REPO" "$SINCE" "$UNTIL" >&2
  printf '%s %s %s %s\n' "$OWNER" "$REPO" "$SINCE" "$UNTIL"
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
  cat <<EOF >&2
    Usage: 
      $0 -u [GITHUB_URL]
      $0 -u [GITHUB_URL] -s [YYYY-MM-DD] -un [YYYY-MM-DD]
      $0 -h

    Description:
      GitHub リポジトリのプルリクエスト貢献者を分析し、各ユーザーの貢献度をCSV形式で出力します。

    Parameters:
      -u, --url         リポジトリのURL (デフォルト: https://github.com/ryoppippi/ccusage)
      -s, --since       開始日 (デフォルト: 1970-01-01)
      -un, --until      終了日 (デフォルト: 今日)
      -h, --help        ヘルプを表示

    Output:
      userId,username,pullrequest回数

    Examples:
      $0 -h
      $0 --help
      $0 -u https://github.com/microsoft/vscode
      $0 -u https://github.com/ryoppippi/ccusage -s 2024-01-01 -un 2024-01-01
      $0 --url https://github.com/microsoft/vscode --since 2024-01-01 --until 2024-01-01
EOF

  return 0
}

#--------------------------------------
# 出力ディレクトリの準備
#--------------------------------------
function setup_output_directory() {

  # 結果ディレクトリの準備
  for path in "${CREATE_PATH_ARRAY[@]}"; do
    if [[ ! -d "$path" ]]; then
      mkdir -p "$path"
    fi
  done

  return 0
}

#--------------------------------------
# Description: RateLimitを取得して、メッセージやコストを出力する関数
# Args: message before
# 第一引数: 出力するメッセージ
# 第二引数: （任意）前回の残りのリミット
# Example: get_ratelimit "before-get-pull-request" "100"
#--------------------------------------
function get_ratelimit() {
  local message="$1" before="${2:-}" is_output="${3:-true}"
  local remaining cost

  remaining="$(gh api graphql -f query='query(){ rateLimit { remaining } }' --jq '.data.rateLimit.remaining')"

  printf '%s:remaining:%s\n' "$message" "$remaining" >&2

  if [[ "$before" =~ ^[0-9]+$ && "$remaining" =~ ^[0-9]+$ ]]; then
    cost=$((before - remaining))
    printf '%s:cost:%d\n' "$message" "$cost" >&2
  fi

  if [[ "$is_output" == "true" ]]; then
    printf '%s\n' "$remaining"
  fi
}
