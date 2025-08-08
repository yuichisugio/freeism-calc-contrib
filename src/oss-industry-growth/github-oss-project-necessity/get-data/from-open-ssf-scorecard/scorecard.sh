#!/bin/bash

# OpenSSF Scorecardのデータを取得するファイル

set -euo pipefail

# 一旦は、GitHubのインサイト取得に集中するつもりなので実装しない

scorecard --repo=github.com/ossf/scorecard --format=json > scorecard.json --token="$1"
