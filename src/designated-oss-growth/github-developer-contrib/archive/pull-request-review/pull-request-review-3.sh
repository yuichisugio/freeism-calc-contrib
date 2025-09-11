#!/bin/bash

# --------------------------------------
# Pull Request Review関連のtotalCountをテスト的に取得する
# --------------------------------------

set -euo pipefail

# shellcheck disable=SC2016
gh api graphql \
  --paginate --slurp \
  --header X-Github-Next-Global-ID:1 \
  -f owner="${1:-yuichisugio}" \
  -f name="${2:-myFirstTest}" \
  -f query='
    query($owner: String!, $name: String!, $endCursor: String) {
      repository(owner:$owner, name:$name) {
        pullRequests(first: 100 ,after:$endCursor,orderBy:{field : CREATED_AT,direction: ASC}){
          totalCount
          pageInfo { hasNextPage endCursor }
          nodes { 
            author { login url }
            createdAt
            comments(first: 1){ totalCount }
            labels(first: 1){ totalCount }
            participants(first: 1) { totalCount }
            reactions(first:1){ totalCount }
            reviewRequests(first: 1){ totalCount }
            reviewThreads(first: 1){ totalCount }
            reviews(first: 1){ totalCount }
            timelineItems(first: 1){ totalCount }
          }
        }
      }
    }
  ' | jq '.'> ./src/designated-oss-growth/github-developer-contrib/archive/pull-request-review/pull-request-review-3.json
