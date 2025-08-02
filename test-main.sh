#!/bin/bash

# デフォルト設定
OWNER=${1:-"yoshiko-pg"}
REPO=${2:-"difit"}

# 共通関数を読み込む
source "$(dirname "$0")/calc-contrib/utils.sh"

# プルリクエスト貢献者を分析。
# source "$(dirname "$0")/calc-contrib/get-github-pull-request.sh"

# イシュー貢献者を分析。
source "$(dirname "$0")/calc-contrib/get-github-issue.sh"

# 貢献度の重み付け
# source "$(dirname "$0")/calc-contrib/contrib-weighting.sh"

# 貢献度の合計を計算する
# source "$(dirname "$0")/calc-contrib/calc-amount-contrib.sh"

# 出力ディレクトリの準備
setup_output_directory

# プルリクエスト貢献者を分析。
# get_github_pull_request_contributors

# イシュー貢献者を分析。
# get_github_issue_contributors
