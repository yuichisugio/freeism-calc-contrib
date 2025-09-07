#!/bin/bash

#--------------------------------------
# GitHub APIからReactionを取得する
# Reactableインターフェースを実装した、Issue / IssueComment / PullRequest / PullRequestReview / PullRequestReviewComment / Discussion / DiscussionComment / TeamDiscussion / TeamDiscussionComment / CommitComment / ReleaseのReactionを取得する。
#--------------------------------------

set -euo pipefail

cd "$(cd "$(dirname -- "$0")" && pwd -P)"

#--------------------------------------
# Issue/IssueCommentのnode_idを取得する関数
# 作成したIssue・そのIssue へのコメントのNodeIdを取得
#--------------------------------------
function get_issue_node_id() {
  local OWNER="$1" REPO="$2" SINCE="${3}" QUERY
  
  # shellcheck disable=SC2016
  QUERY='
    query($owner:String!, $name:String!, $endCursor:String, $since:String) {
    repository(owner:$owner, name:$name) {
      issues(first:100, after:$endCursor, orderBy:{field:UPDATED_AT, direction:DESC}) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          url
          number
          comments(first:100) {
            nodes { id url createdAt }
            pageInfo { hasNextPage endCursor }
          }
        }
      }
    }
  '

  # クエリを実行。jq '.' で、JSONを指定ファイルに出力。
  gh api graphql --paginate \
    -F owner="$OWNER" -F name="$REPO" -F since="$SINCE" -f query="$QUERY" \
    --jq '.data.repository.issues.nodes[] | [.id, .url] , (.comments.nodes[]?|[.id, .url])' \
    >node_ids.ndjson

  # 終了ステータスを成功にする
  return 0
}

#--------------------------------------
# Reactionを取得する流れを統括する関数
#--------------------------------------
function get_reaction() {

  # 引数の値
  local owner="$1" repo="$2" since="${3}"

  # shellcheck disable=SC2016
  gh api graphql -F owner="$owner" -F name="$repo" -F since="$since" -f query='
    query($owner: String!, $name: String!, $since: String!) {
      repository(owner: $owner, name: $name) {
        reactions(first: 100, since: $since) {
          nodes {
            id
            content
          }
        }
      }
    }
  '

  # 終了ステータスを成功にする
  return 0
}

get_reaction "$@" || exit 1
