#!/usr/bin/env bash

set -euo pipefail

readonly RAW_SPONSOR_RECIPIENTS_PATH="./src/designated-oss-growth/github-developer-contrib/archive/sponsor/raw-sponsor-recipients.json"
readonly PROCESSED_SPONSOR_RECIPIENTS_PATH="./src/designated-oss-growth/github-developer-contrib/archive/sponsor/processed-sponsor-recipients.txt"
readonly RAW_SPONSOR_SUPPORTERS_PATH="./src/designated-oss-growth/github-developer-contrib/archive/sponsor/raw-sponsor-supporters.json"

function get_sponsors_recipients() {
  local owner="${1:-ryoppippi}" repo="${2:-ccusage}" QUERY

  # shellcheck disable=SC2016
  QUERY='
    query($owner:String!, $name:String!) {
      repository(owner:$owner, name:$name) {
        owner { login __typename }
        fundingLinks { platform url }
      }
    }
  '

  gh api graphql -f owner="$owner" -f name="$repo" -f query="$QUERY" | jq '.' >"$RAW_SPONSOR_RECIPIENTS_PATH"

  jq -r '
    .data.repository as $r
    | ([$r.owner.login]                       # Owner
      + ($r.fundingLinks
      | map(select(.platform=="GITHUB")   # GitHub Sponsors のみ
      | .url
      | capture("/sponsors/(?<login>[^/?#]+)/*$").login)))
    | unique[]
  ' "$RAW_SPONSOR_RECIPIENTS_PATH" >"$PROCESSED_SPONSOR_RECIPIENTS_PATH"

  return 0
}

function get_github_sponsors_supporters() {

  # shellcheck disable=SC2016
  QUERY='
    query($login: String!, $endCursor: String) {
      repositoryOwner(login: $login) {
        __typename
        ... on User { ...SponsorableFields }
        ... on Organization { ...SponsorableFields }
      }
    }

    fragment SponsorableFields on Sponsorable {
      sponsorshipsAsMaintainer(first: 100, after: $endCursor,activeOnly: false) {
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
        pageInfo { hasNextPage endCursor }
      }
    }
  '

  while read -r LOGIN; do
    gh api graphql --paginate --slurp -F login="$LOGIN" -f query="$QUERY" |
      jq '.' >"$RAW_SPONSOR_SUPPORTERS_PATH"
  done <"$PROCESSED_SPONSOR_RECIPIENTS_PATH"
}

get_ratelimit() {
  printf '%s\n' "$(gh api graphql -f query='
  query(){
    rateLimit { remaining }
  }' --jq '.data.rateLimit.remaining')"
}

function get_sponsors() {
  printf 'before--sponsor-remaining:%s\n' "$(get_ratelimit)"
  get_sponsors_recipients "$@"
  get_github_sponsors_supporters "$@"
  printf 'after-sponsor-remaining:%s\n' "$(get_ratelimit)"
}

get_sponsors "$@"
