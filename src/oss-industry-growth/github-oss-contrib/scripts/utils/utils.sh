#!/bin/bash

# 共通関数を定義するファイル

set -euo pipefail

# 使用方法の表示
show_usage() {
  cat <<EOF
    Usage: 
      $0 [OWNER] [REPO] [GITHUB_AUTH_TOKEN]

    Description:
      GitHub リポジトリから情報を取得して、
    「OSS業界全体の発展」に貢献しているかを分析します。

    Parameters:
      OWNER    リポジトリのオーナー名 (デフォルト: yoshiko-pg)
      REPO     リポジトリ名 (デフォルト: difit)
      GITHUB_AUTH_TOKEN  GitHub の Personal Access Token

    Output:
      - 

    Examples:
      $0 yoshiko-pg difit 1234567890
EOF

  return 0
}

# 出力ディレクトリの準備
setup_output_directory() {

  if [[ ! -d "$RESULTS_DIR" ]]; then
    mkdir -p "$RESULTS_DIR"
  fi

  if [[ ! -d "$PULL_REQUEST_DIR" ]]; then
    mkdir -p "$PULL_REQUEST_DIR"
  fi

  if [[ ! -d "$ISSUE_DIR" ]]; then
    mkdir -p "$ISSUE_DIR"
  fi

  return 0
}
