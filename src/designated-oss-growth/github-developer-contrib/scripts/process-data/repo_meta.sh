#!/bin/bash

#--------------------------------------
# リポジトリのメタデータを加工する
#--------------------------------------

set -euo pipefail

cd "$(cd "$(dirname -- "$0")" && pwd -P)"

function process_repo_meta() {
  local RAW_DATA_PATH PROCESSED_DATA_PATH

  readonly RAW_DATA_PATH="../../archive/raw-data.json"
  readonly PROCESSED_DATA_PATH="../../archive/processed-data.json"

  jq '{
        host:"github.com",
        ownerUsername:.data.repository.owner.login,
        ownerUserId:(.data.repository.owner.id|tostring),
        repositoryName:.data.repository.name,
        repositoryId:(.data.repository.id|tostring),
        repositoryUrl:.data.repository.url,
        createdAt:.data.repository.createdAt,
        defaultBranch:.data.repository.defaultBranchRef.name
      }' "$RAW_DATA_PATH" >"$PROCESSED_DATA_PATH"

  return 0
}
