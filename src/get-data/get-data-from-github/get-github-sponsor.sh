#!/bin/bash

# GitHub Sponsors関連のデータ取得を行うファイル

set -euo pipefail

# GitHub Sponsors関連のデータ取得を行う関数
function get_github_sponsor() {

  # 結果を格納する変数を先に宣言。
  # localも終了ステータスを持つので、↓と宣言と一緒に結果を入れると終了ステータスが正しく入らない。
  local result

  # ↓は、シェルスクリプトの静的解析ツールであるshellcheckに対して、GraphQL変数を使用したいので、""を使用する警告を無視して、''を使用できるように指示するもの。
  # shellcheck disable=SC2016
  result=$(
    gh api graphql -f query='
      query {
        viewer {
          sponsorshipsAsMaintainer(first: 100) {
            nodes {
              tier {
                name
              }
            }
          }
        }
      }
    '
  )

  # 結果を返す
  echo "$result"
}
