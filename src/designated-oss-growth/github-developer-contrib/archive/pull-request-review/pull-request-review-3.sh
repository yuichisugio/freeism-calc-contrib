#!/bin/bash

# --------------------------------------
# Pull Request Review関連のtotalCountをテスト的に取得する
# --------------------------------------

readonly OWNER="${1:-yuichisugio}"
readonly REPO="${2:-myFirstTest}"
readonly RAW_OUTPUT_FILE="./src/designated-oss-growth/github-developer-contrib/archive/pull-request-review/${REPO}-3-raw.json"
readonly OUTPUT_FILE="./src/designated-oss-growth/github-developer-contrib/archive/pull-request-review/${REPO}-3.json"

set -euo pipefail

# shellcheck disable=SC2016
gh api graphql \
  --paginate --slurp \
  --header X-Github-Next-Global-ID:1 \
  -f owner="${OWNER}" \
  -f name="${REPO}" \
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
            timelineItems(first: 1){ totalCount }
            reviewThreads(first: 30){ totalCount nodes { comments(first: 1){ totalCount } } }
            reviews(first: 30){ totalCount nodes { comments(first: 1){ totalCount } } }
            latestReviews(first: 30){ totalCount nodes { comments(first: 1){ totalCount } } }
            latestOpinionatedReviews(first: 30){ totalCount nodes { comments(first: 1){ totalCount } } }
          }
        }
      }
    }
    ' | jq '.' >"${RAW_OUTPUT_FILE}"

jq '
    def max0(a): (if (a|length)>0 then (a|max) else 0 end);
    . as $pages
    | ($pages[0].data.repository.pullRequests.totalCount) as $pr_total
    | [ $pages[] | .data.repository.pullRequests.nodes[] ] as $nodes
    | {
        pullRequests_totalCount: $pr_total,
        comments_max:       max0([ $nodes[] | .comments.totalCount ]),
        labels_max:         max0([ $nodes[] | .labels.totalCount ]),
        participants_max:   max0([ $nodes[] | .participants.totalCount ]),
        reactions_max:      max0([ $nodes[] | .reactions.totalCount ]),
        timelineItems_max:  max0([ $nodes[] | .timelineItems.totalCount ]),
        reviewRequests_max: max0([ $nodes[] | .reviewRequests.totalCount ]),
        reviewThreads_max:  max0([ $nodes[] | .reviewThreads.totalCount ]),
        reviewThreads_comments_max: max0([ $nodes[] | ([.reviewThreads.nodes[]? | .comments.totalCount] | max0(.)) ]),
        reviews_max:        max0([ $nodes[] | .reviews.totalCount ]),
        reviews_comments_max: max0([ $nodes[] | ([.reviews.nodes[]? | .comments.totalCount] | max0(.)) ]),
        latestReviews_max:  max0([ $nodes[] | .latestReviews.totalCount ]),
        latestReviews_comments_max: max0([ $nodes[] | ([.latestReviews.nodes[]? | .comments.totalCount] | max0(.)) ]),
        latestOpinionatedReviews_max:  max0([ $nodes[] | .latestOpinionatedReviews.totalCount ]),
        latestOpinionatedReviews_comments_max: max0([ $nodes[] | ([.latestOpinionatedReviews.nodes[]? | .comments.totalCount] | max0(.)) ]),
      }
  ' "${RAW_OUTPUT_FILE}" >"${OUTPUT_FILE}"
