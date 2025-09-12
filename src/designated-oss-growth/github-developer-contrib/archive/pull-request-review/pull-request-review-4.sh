#!/bin/bash

# --------------------------------------
# Pull Request のReview関連のデータをテスト的に取得する
# --------------------------------------

readonly OWNER="${1:-yuichisugio}"
readonly REPO="${2:-myFirstTest}"
readonly OUTPUT_FILE="./src/designated-oss-growth/github-developer-contrib/archive/pull-request-review/${REPO}-4.json"

set -euo pipefail

# shellcheck disable=SC2016
gh api graphql \
  --header X-Github-Next-Global-ID:1 \
  -f owner="${OWNER}" \
  -f name="${REPO}" \
  -f query='
    query($owner: String!, $name: String!) {
      repository(owner:$owner, name:$name) {
        pullRequests(first: 100 ,orderBy: {field : CREATED_AT,direction: ASC}){
          totalCount
          pageInfo { hasNextPage endCursor }
          nodes {
            fullDatabaseId
            id # node_id
            permalink
            number
            additions
            deletions
            title # pull-requestもレビューする対象なのでコード行数に加算するために取得
            state
            reviewDecision
            mergeStateStatus
            mergeable
            createdAt # draftの作成日だがレビュー開始日ではない
            publishedAt # draftからOpenになった日 or 直接Openになった日
            closedAt
            mergedBy { login url }
            mergedAt
            reactionGroups { content reactors { totalCount } }
            totalCommentsCount
            comments(first: 20){
              totalCount
              nodes {
                fullDatabaseId
                author { login url }
                bodyText
                createdAt
                url
                reactionGroups { content reactors { totalCount } }
              }
            }
            reviewRequests(first: 3){
              totalCount
              nodes {
                databaseId
                requestedReviewer {
                  __typename
                  ... on User { login name url databaseId }
                  ... on Bot { login url databaseId }
                  ... on Team { name url databaseId }
                  ... on Mannequin { login name url databaseId }
                }
              }
            }
            latestReviews(first: 30){
              totalCount
              nodes {
                fullDatabaseId
                url
                author { login url }
                bodyText
                state
                submittedAt
                publishedAt
                reactionGroups { content reactors { totalCount } }
                updatedAt
              }
            }
            reviewThreads(first: 30){
              totalCount
              nodes {
                subjectType
                comments(first: 50){
                  totalCount
                  nodes {
                    fullDatabaseId
                    url
                    author { login url }
                    bodyText
                    createdAt
                    publishedAt
                    reactionGroups { content reactors { totalCount } }
                  }
                }
              }
            }
            reviews(first: 30){
              totalCount
              nodes {
                fullDatabaseId
                url
                author { login url }
                bodyText
                state
                submittedAt
                createdAt
                publishedAt
                bodyText
                reactionGroups { content reactors { totalCount } }
                comments(first: 50){
                  totalCount
                  nodes {
                    fullDatabaseId
                    url
                    author { login url }
                    bodyText
                    subjectType
                    createdAt
                    publishedAt
                    reactionGroups { content reactors { totalCount } }
                  }
                }
              }
            }
            timelineItems(first: 100){
              totalCount
              nodes {
                __typename
                ... on ReviewRequestedEvent { createdAt requestedReviewer { __typename ... on User { login url } ... on Team { name url } } actor { login } }
                ... on ReadyForReviewEvent { createdAt actor { login } }
                ... on MergedEvent { createdAt mergeRefName }
                ... on ClosedEvent { createdAt }
              }
            }
          }
        }
      }
    }
  ' | jq '.' >"${OUTPUT_FILE}"
