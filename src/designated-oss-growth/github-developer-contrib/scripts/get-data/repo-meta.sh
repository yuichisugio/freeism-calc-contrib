#!/bin/bash

#--------------------------------------
# リポジトリのメタデータを取得する
#--------------------------------------

set -euo pipefail

cd "$(cd "$(dirname -- "$0")" && pwd -P)"

usage() {
  cat <<EOF
  Usage: $(basename "$0") <repo>
    <repo> can be "owner/repo" or a full GitHub URL.
  Output: single JSON with repository meta (created_at, default_branch, url, id, owner)
EOF
}

main() {
  require_tools
  [[ $# -ge 1 ]] || {
    usage
    exit 1
  }
  read -r OWNER REPO < <(parse_repo "$1")

  gh api -H "Accept: application/vnd.github+json" "/repos/${OWNER}/${REPO}" |
    jq '{
        host:"github.com",
        owner:.owner.login,
        ownerId:(.owner.id|tostring),
        repository:.name,
        repositoryId:(.id|tostring),
        url:.html_url,
        createdAt:.created_at,
        defaultBranch:.default_branch
      }'
}
main "$@"
