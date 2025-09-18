#!/usr/bin/env bash

#--------------------------------------
# sponsor関連のデータ取得を行うファイル
#--------------------------------------

set -euo pipefail

#--------------------------------------
# 出力先のファイルを定義
#--------------------------------------
readonly RESULT_GET_SPONSOR_DIR="${OUTPUT_GET_DIR}/sponsor"
readonly RAW_SPONSOR_RECIPIENTS_PATH="${RESULT_GET_SPONSOR_DIR}/raw-sponsor-recipients.json"
readonly PROCESSED_SPONSOR_RECIPIENTS_PATH="${RESULT_GET_SPONSOR_DIR}/processed-sponsor-recipients.txt"
readonly RAW_SPONSOR_SUPPORTERS_PATH="${RESULT_GET_SPONSOR_DIR}/raw-sponsor-supporters.json"

mkdir -p "$RESULT_GET_SPONSOR_DIR"

#--------------------------------------
# スポンサーを受け取る人のデータを取得
#--------------------------------------
function get_github_sponsors_recipients() {
  local QUERY

  # shellcheck disable=SC2016
  QUERY='
    query($owner:String!, $name:String!) {
      repository(owner:$owner, name:$name) {
        hasSponsorshipsEnabled
        homepageUrl
        owner { login __typename }
        fundingLinks { platform url }
      }
    }
  '

  gh api graphql -f owner="$OWNER" -f name="$REPO" -f query="$QUERY" | jq '.' >"$RAW_SPONSOR_RECIPIENTS_PATH"

  jq -r '
    .data.repository as $r
    | ([$r.owner.login]                   # Owner
      + ($r.fundingLinks
      | map(select(.platform=="GITHUB")   # GitHub Sponsors のみ
      | .url
      | capture("/sponsors/(?<login>[^/?#]+)/*$").login)))
    | unique[]
  ' "$RAW_SPONSOR_RECIPIENTS_PATH" >"$PROCESSED_SPONSOR_RECIPIENTS_PATH"
}

#--------------------------------------
# スポンサーを提供する人のデータを取得
#--------------------------------------
function get_github_sponsors_supporters() {

  local QUERY

  # shellcheck disable=SC2016
  QUERY='
    query($login: String!, $endCursor: String, $perPage: Int!) {
      repositoryOwner(login: $login) {
        __typename
        ... on User { ...SponsorableFields }
        ... on Organization { ...SponsorableFields }
      }
    }

    fragment SponsorableFields on Sponsorable {
      sponsorshipsAsMaintainer(first: $perPage, after: $endCursor,activeOnly: false) {
        totalCount
        pageInfo { hasNextPage endCursor }
        nodes {
          privacyLevel
          isActive
          isOneTimePayment
          paymentSource
          createdAt
          tierSelectedAt
          tier { name monthlyPriceInCents monthlyPriceInDollars updatedAt createdAt description isCustomAmount isOneTime }  # ティア金額（見える場合）
          sponsorEntity {
            __typename
            ... on User { login name url }
            ... on Organization { login name url }
          }
        }
      }
    }
  '

  # スポンサーされている人ごとに、そのスポンサーを提供する人のデータを繰り返し処理で取得
  while read -r LOGIN; do
    gh api graphql \
      --paginate --slurp \
      -F login="$LOGIN" \
      -F perPage=50 \
      -f query="$QUERY" |
      jq '.' >"$RAW_SPONSOR_SUPPORTERS_PATH"
  done <"$PROCESSED_SPONSOR_RECIPIENTS_PATH"
}

#--------------------------------------
# sponsor関連のデータ取得を行う関数
#--------------------------------------
function get_sponsor() {
  # データ取得前のRateLimit変数
  local before_remaining_ratelimit
  # データ取得前のRateLimitを取得
  before_remaining_ratelimit="$(get_ratelimit "before:get-sponsor()")"

  # スポンサーを受け取る人のデータを取得
  get_github_sponsors_recipients

  # スポンサーを提供する人のデータを取得
  get_github_sponsors_supporters

  # データ取得後のRateLimitを出力
  get_ratelimit \
    "after:get-sponsor()" \
    "$before_remaining_ratelimit" \
    "false"
}
