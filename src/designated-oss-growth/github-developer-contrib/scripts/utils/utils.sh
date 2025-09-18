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
  local SINCE="1970-01-01T00:00:00Z" # ドキュメント上の最小値
  local UNTIL="2099-12-13T23:59:59Z" # ドキュメント上の最大値

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
    -r | --ratelimit)
      get_ratelimit "ratelimit" null "false"
      exit 1
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
# 使い方の表示
#--------------------------------------
function show_usage() {
  cat <<EOF >&2
    Usage: 
      $0 -u [GITHUB_URL]
      $0 -u [GITHUB_URL] -s [YYYY-MM-DD] -un [YYYY-MM-DD]
      $0 -r
      $0 -h

    Description:
      GitHub リポジトリのプルリクエスト貢献者を分析し、各ユーザーの貢献度をCSV形式で出力します。

    Parameters:
      -u, --url         リポジトリのURL (デフォルト: https://github.com/ryoppippi/ccusage)
      -s, --since       開始日 (デフォルト: 1970-01-01)
      -un, --until      終了日 (デフォルト: 今日)
      -r, --ratelimit   リミットを表示
      -h, --help        ヘルプを表示

    Output:
      userId,username,pullrequest回数

    Examples:
      $0 -h
      $0 --help
      $0 -u https://github.com/microsoft/vscode
      $0 -u https://github.com/ryoppippi/ccusage -s 2024-01-01 -un 2024-01-01
      $0 --url https://github.com/microsoft/vscode --since 2024-01-01 --until 2024-01-01
      $0 -r
EOF

  return 0
}

#--------------------------------------
# Description: RateLimitを取得して、メッセージやコストを出力する関数
# Args: message before
# 第一引数: 出力するメッセージ
# 第二引数: （任意）前回の残りのリミット
# Example: get_ratelimit "before-get-pull-request" "50"
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
