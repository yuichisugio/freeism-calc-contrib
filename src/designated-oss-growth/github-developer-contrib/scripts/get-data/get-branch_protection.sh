#!/bin/bash

#--------------------------------------
# ブランチ保護ルールを取得する
#--------------------------------------

set -euo pipefail

cd "$(cd "$(dirname -- "$0")" && pwd -P)"

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

main() {
  read -r OWNER REPO < <(parse_repo "$1")

  # First page (also includes defaultBranchRef)
  first="$(gql_call "$QUERY" "$OWNER" "$REPO")"
  echo "$first" | jq -c '.data.repository.defaultBranchRef' | jq '{defaultBranchRef:.}'
  echo "$first" | jq -c '.data.repository.branchProtectionRules.nodes[]'
  # Remaining pages for rules
  cursor=$(echo "$first" | jq -r '.data.repository.branchProtectionRules.pageInfo.endCursor')
  has_next=$(echo "$first" | jq -r '.data.repository.branchProtectionRules.pageInfo.hasNextPage')
  while [[ "$has_next" == "true" && "$cursor" != "null" ]]; do
    page="$(gql_call "$QUERY" "$OWNER" "$REPO" "$cursor")"
    echo "$page" | jq -c '.data.repository.branchProtectionRules.nodes[]'
    has_next=$(echo "$page" | jq -r '.data.repository.branchProtectionRules.pageInfo.hasNextPage')
    cursor=$(echo "$page" | jq -r '.data.repository.branchProtectionRules.pageInfo.endCursor')
  done
}
main "$@"
