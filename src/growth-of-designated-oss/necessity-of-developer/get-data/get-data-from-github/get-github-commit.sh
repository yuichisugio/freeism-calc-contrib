#!/bin/bash

# コミットデータを取得する

set -euo pipefail

# コミットデータを取得する
get_github_commit_data() {
  local owner="yoshiko-pg"
  local repo="difit"
  local output_file="output/github-commit.csv"

  # コミットデータを取得
  curl -s "https://api.github.com/repos/$owner/$repo/commits" | jq -r '.[] | {
    sha: .sha,
    author: .author.login,
    date: .commit.author.date
  }' | tee "$output_file"

  return 0
}
