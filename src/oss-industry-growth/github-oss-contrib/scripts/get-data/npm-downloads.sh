#!/bin/bash

# --------------------------------------
# npmのダウンロード数を取得するファイル
# npm apiの最古公開日が2015-01-10.
# npm apiは1回のクエリで18ヶ月のデータを取得できる。
# なので、最古公開日から18ヶ月ごとに日付をイテレートして取得する。
# --------------------------------------

set -euo pipefail

get_npm_downloads() {

  printf '%s\n' "begin:get_npm_downloads()"

  local pkg="${1:-${NPM_NAME:-}}"
  if [[ -z "${pkg}" ]]; then
    echo "package name required (arg or \$NPM_NAME)" >&2
    return 1
  fi

  # npm downloads API は単一パッケージの range 取得が 1リクエスト=最大18ヶ月。:contentReference[oaicite:1]{index=1}
  local start="2015-01-10" # 公開されている最古日
  local from_date="$start"
  local end_all
  end_all="$(date -u +%F)" # 今日 (UTC)

  # 一時ファイル
  local tmp_data tmp_json
  tmp_data="$(mktemp)"
  tmp_json="$(mktemp)"
  trap 'rm -f "$tmp_data" "$tmp_json"' EXIT

  # パッケージ名をURLエンコード（scoped等に対応）
  local enc_pkg
  enc_pkg="$(printf '%s' "$pkg" | jq -sRr @uri)"

  local calls=0

  while :; do
    # チャンク終端（startから18ヶ月後）
    local chunk_end end
    chunk_end="$(date -u -d "$start +18 months" +%F)"
    end="$chunk_end"
    # 最終日を超えないように調整
    if [[ "$(date -u -d "$end" +%s)" -gt "$(date -u -d "$end_all" +%s)" ]]; then
      end="$end_all"
    fi

    local url="https://api.npmjs.org/downloads/range/${start}:${end}/${enc_pkg}"
    echo "GET $url" >&2

    # 429/一時エラー対策の簡易リトライ（指数バックオフ）
    local ok=0
    for i in 0 1 2 3 4; do
      if curl -fsS "$url" -o "$tmp_json"; then
        ok=1
        break
      fi
      sleep $((2 ** i))
    done
    if [[ "$ok" -ne 1 ]]; then
      echo "Failed to fetch: $url" >&2
      return 1
    fi
    calls=$((calls + 1))

    # 期待する配列が無い場合はエラー内容を表示
    if ! jq -e '.downloads and (.downloads | type=="array")' <"$tmp_json" >/dev/null; then
      echo "Unexpected response for $url:" >&2
      jq -r '.error // .reason // .message // .|tostring' <"$tmp_json" >&2 || true
      return 1
    fi

    # 日別レコードを追記
    jq -c '.downloads[]' <"$tmp_json" >>"$tmp_data"

    # 終了判定（end が最終日）
    if [[ "$end" == "$end_all" ]]; then
      break
    fi

    # 次チャンク開始は end の翌日
    start="$(date -u -d "$end +1 day" +%F)"
  done

  # 重複日（境界）があっても「最後に得た値を採用」しつつ昇順に整列し、合計を計算
  jq -s --arg pkg "$pkg" --arg from "$from_date" --arg to "$end_all" --argjson calls "$calls" '
    group_by(.day) | map(.[-1]) | sort_by(.day) as $rows
    | {
        package: $pkg,
        from: $from,
        to: $to,
        days: ($rows | length),
        totalDownloads: ($rows | map(.downloads) | add),
        api: "https://api.npmjs.org/downloads/range/{from}:{to}/{package}",
        chunkMonths: 18,
        calls: $calls,
        downloads: $rows
      }
  ' "$tmp_data"

  printf '%s\n' "end:get_npm_downloads()"
}
