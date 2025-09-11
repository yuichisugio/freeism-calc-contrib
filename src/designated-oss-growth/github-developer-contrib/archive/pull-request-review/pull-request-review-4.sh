#!/bin/bash

# --------------------------------------
# Pull Request のReview関連のデータをテスト的に取得する
# --------------------------------------

set -euo pipefail

# shellcheck disable=SC2016
gh api graphql \
  --header X-Github-Next-Global-ID:1 \
  -f owner="${1:-yuichisugio}" \
  -f name="${2:-myFirstTest}" \
  -f query='
    query($owner: String!, $name: String!) {
      repository(owner:$owner, name:$name) {
        pullRequests(first: 100 ,orderBy:{field : CREATED_AT,direction: ASC}){
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
            comments(first: 100){ 
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
            reviewRequests(first: 100){ 
              totalCount 
              nodes {
                databaseId
                requestedReviewer { 
                  __typename 
                  ... on User { login name url databaseId } 
                  ... on Bot { login url databaseId }
                  ... on Team { name login url databaseId }
                  ... on Mannequin { login name url databaseId }
                }
              }
            }
            latestReviews(first: 100){
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
            reviewThreads(first: 100){ 
              totalCount 
              nodes {
                comments(first: 100){ 
                  totalCount
                  nodes { 
                    comments(first: 100){ 
                      totalCount
                      nodes {
                        fullDatabaseId
                        url
                        author { login url } 
                        createdAt # Openのコメントの作成日（draftも含む）
                        publishedAt # Openのコメントの作成日
                        bodyText
                        reactionGroups { content reactors { totalCount } } 
                      }
                    }
                    subjectType
                  } }
              }
            }
            reviews(first: 100){ 
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
                reactionGroups { content reactors { totalCount } }
                comments(first: 100){ 
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
                  bodyText
                  createdAt
                  publishedAt
                  reactionGroups { content reactors { totalCount } }
                }
              }
            }
            timelineItems(first: 100){ 
              totalCount 
              nodes {
                __typename
                ... on ReviewRequestedEvent { createdAt requestedReviewer { __typename ... on User { login url } ... on Team { name login url } } actor { login } }
                ... on ReadyForReviewEvent { createdAt actor { login } }
                ... on MergedEvent { createdAt mergeRefName }
                ... on ClosedEvent { createdAt }
              }
            }
          }
        }
      }
    }
  ' | jq '.'> ./src/designated-oss-growth/github-developer-contrib/archive/pull-request-review/pull-request-review-4.json
