#!/bin/bash

# GitHub APIから取得したデータを、扱いやすいように加工する

set -euo pipefail

# プルリクエストのデータを加工
function process_pr_data() {

  # 出力ファイルのパス
  local pr_output_file
  pr_output_file="${PULL_REQUEST_DIR}/${OWNER}_${REPO}_$(date +%Y%m%d_%H%M%S).json"

  echo "$1" |
    jq -r '
      .data.repository.pullRequests
        | {
        pr_id: .number,
        pr_title: .title,
        pr_body: .body,
        pr_created_at: .created_at,
        pr_updated_at: .updated_at,
        pr_merged_at: .merged_at,
        pr_closed_at: .closed_at,
        pr_assignees: .assignees,
        pr_reviewers: .reviewers,
        pr_comments: .comments
      }
      ' |
    tee "$pr_output_file"

  return 0
}

# コミットのデータを加工
function process_commit_data() {
  local commit_data_file="${1:-}"
  local output_file="${2:-}"

  jq -r '
    .[] | {
      commit_id: .sha,
      commit_message: .commit.message,
      commit_author: .commit.author.name,
      commit_date: .commit.author.date
    }
  ' "$commit_data_file" >"$output_file"

  return 0
}

# イシューのデータを加工
function process_issue_data() {
  local issue_data_file="${1:-}"
  local output_file="${2:-}"

  jq -r '
    .[] | {
      issue_id: .number,
      issue_title: .title,
      issue_body: .body,
      issue_created_at: .created_at,
      issue_updated_at: .updated_at,
      issue_closed_at: .closed_at,
      issue_assignees: .assignees,
      issue_comments: .comments
    }
  ' "$issue_data_file" >"$output_file"

  return 0
}
