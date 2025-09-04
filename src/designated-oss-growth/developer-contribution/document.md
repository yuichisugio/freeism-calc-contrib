# developer contribution

## 概要


### 使い方

```shell
./main.sh [option] [path]
```

### 出力形式

```json
{
	"meta": {
		"createdAt": "2025-08-20",
		"specified-oss": {
			"owner": "ryoppippi",
			"Repository": "ccusage"
		}
	},
	"data": [
		{
			"host": "gitlab.com",
			"owner": "group",
			"repo": "lib-b",
			"evaluation": {
				"result": 3
				"evaluationCriteria": {
					"timeResources": 3
				}
			}
		},
		{
			"host": "github.com",
			"owner": "acme",
			"repo": "lib-a",
			"package_manager_url": "pack-D",
			"homepage": "page-p",
			"repository_url": "git/e"
		}
	]
}
```

### 仕様
