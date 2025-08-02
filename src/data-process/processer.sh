#!/bin/bash

# GitHub APIから取得したデータを、扱いやすいように加工する

set -euo pipefail

# プルリクエストのデータを加工
function process_pr_data() {
  local pr_data_file="${1:-}"
  local output_file="${2:-}"

  jq -r '
    .[] | {
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
  ' "$pr_data_file" > "$output_file"
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
  ' "$commit_data_file" > "$output_file"
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
  ' "$issue_data_file" > "$output_file"
}

# スターのデータを加工
function process_star_data() {
  local star_data_file="${1:-}"
  local output_file="${2:-}"

  jq -r '
    .[] | {
      star_id: .id,
      star_created_at: .created_at
    }
  ' "$star_data_file" > "$output_file"
}

# forkのデータを加工
function process_fork_data() {
  local fork_data_file="${1:-}"
  local output_file="${2:-}"

  jq -r '
    .[] | {
      fork_id: .id,
      fork_created_at: .created_at
    }
  ' "$fork_data_file" > "$output_file"
}

# watchのデータを加工
function process_watch_data() {
  local watch_data_file="${1:-}"
  local output_file="${2:-}"

  jq -r '
    .[] | {
      watch_id: .id,
      watch_created_at: .created_at
    }
  ' "$watch_data_file" > "$output_file"
}

# installのデータを加工
function process_install_data() {
  local install_data_file="${1:-}"
  local output_file="${2:-}"

  jq -r '
    .[] | {
      install_id: .id,
      install_created_at: .created_at
    }
  ' "$install_data_file" > "$output_file"
}
