#!/bin/bash

# 共通関数を定義するファイル

# 使用方法の表示
show_usage() {
  cat <<EOF
    Usage: $0 [OWNER] [REPO]

    GitHub リポジトリのプルリクエスト貢献者を分析し、
    各ユーザーの貢献度をCSV形式で出力します。

    Parameters:
      OWNER    リポジトリのオーナー名 (デフォルト: cli)
      REPO     リポジトリ名 (デフォルト: cli)

    Output:
      userId,username,pullrequest回数

    Examples:
      $0                    # cli/cli を分析
      $0 facebook react     # facebook/react を分析
      $0 microsoft vscode   # microsoft/vscode を分析
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
