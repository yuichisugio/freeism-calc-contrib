#!/bin/bash

#--------------------------------------
# ブランチ保護ルールを取得する
#--------------------------------------

set -euo pipefail

cd "$(cd "$(dirname -- "$0")" && pwd -P)"

function get_branch_protection() {
  # 引数の値
  local owner="$1" repo="$2"

  # クエリを定義
  # shellcheck disable=SC2016
  QUERY='
    query($owner:String!, $name:String!, $cursor:String) {
      repository(owner:$owner, name:$name) {
        name
        defaultBranchRef {
          name
          branchProtectionRule {
            id
            pattern
            isAdminEnforced
            requiresApprovingReviews
            requiredApprovingReviewCount
            requiresCodeOwnerReviews
            requiresCommitSignatures
            requiresLinearHistory
            requiresStatusChecks
            requiresStrictStatusChecks
            restrictsPushes
          }
        }
        branchProtectionRules(first:100, after:$cursor) {
          pageInfo { hasNextPage endCursor }
          nodes {
            id
            pattern
            isAdminEnforced
            requiresApprovingReviews
            requiredApprovingReviewCount
            requiresCodeOwnerReviews
            requiresCommitSignatures
            requiresLinearHistory
            requiresStatusChecks
            requiresStrictStatusChecks
            restrictsPushes
          }
        }
      }
    }
  '

  # First page (also includes defaultBranchRef)
  first="$(gh api graphql -F owner="$owner" -F name="$repo" -f query="$QUERY")"
  echo "$first" | jq -c '.data.repository.defaultBranchRef' | jq '{defaultBranchRef:.}' >"$RAW_BRANCH_PROTECTION_DIR"
  echo "$first" | jq -c '.data.repository.branchProtectionRules.nodes[]' >"$RAW_BRANCH_PROTECTION_DIR"
  # Remaining pages for rules
  cursor=$(echo "$first" | jq -r '.data.repository.branchProtectionRules.pageInfo.endCursor')
  has_next=$(echo "$first" | jq -r '.data.repository.branchProtectionRules.pageInfo.hasNextPage')
  while [[ "$has_next" == "true" && "$cursor" != "null" ]]; do
    page="$(gh api graphql -F owner="$owner" -F name="$repo" -f query="$QUERY" -F cursor="$cursor")"
    echo "$page" | jq -c '.data.repository.branchProtectionRules.nodes[]' >"$RAW_BRANCH_PROTECTION_DIR"
    has_next=$(echo "$page" | jq -r '.data.repository.branchProtectionRules.pageInfo.hasNextPage')
    cursor=$(echo "$page" | jq -r '.data.repository.branchProtectionRules.pageInfo.endCursor')
  done

  # 終了ステータスを成功にする
  return 0
}

get_branch_protection "$@"
