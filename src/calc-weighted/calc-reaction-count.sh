#!/bin/bash

# リアクションの数で、5段階評価して、重み付けする。
# 0,1-20,21-50,51-100,101-にする

set -euo pipefail

# リアクションの数を変数に入れる
REACTION_COUNT=$1

# リアクションの数を5段階評価して、重み付け
REACTION_COUNT_WEIGHTED=$(echo "$REACTION_COUNT" | awk '{if ($1 >= 100) print 5; else if ($1 >= 50) print 4; else if ($1 >= 20) print 3; else if ($1 >= 10) print 2; else print 1}')

# 重み付けしたリアクションの数を出力
echo "$REACTION_COUNT_WEIGHTED"
