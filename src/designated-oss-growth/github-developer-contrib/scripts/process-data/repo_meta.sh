#!/bin/bash

#--------------------------------------
# リポジトリのメタデータを加工する
#--------------------------------------

set -euo pipefail

cd "$(cd "$(dirname -- "$0")" && pwd -P)"

function process_repo_meta() {
  jq '{
        host:"github.com",
        ownerUsername:.data.repository.owner.login,
        ownerUserId:(.data.repository.owner.id|tostring),
        repositoryName:.data.repository.name,
        repositoryId:(.data.repository.id|tostring),
        repositoryUrl:.data.repository.url,
        createdAt:.data.repository.createdAt,
        defaultBranch:.data.repository.defaultBranchRef.name
      }' "$RAW_REPO_META_DIR" >"$PROCESSED_REPO_META_DIR"

  return 0
}
