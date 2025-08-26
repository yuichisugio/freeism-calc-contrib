# 評価軸「指定 OSS の発展」

## 概要

- 「指定 OSS の発展」に貢献した開発者を評価をする仕組み
- 評価する対象は、人間・OSS 等さまざま。

## 評価ロジックの種類

1. 「GitHub OSS の開発者」による「指定 OSS の発展」への貢献度を分析
2. 「依存 OSS」による「指定 OSS の発展」への貢献度を分析

## データ取得元

1. GitHub API

## 使い方

1. 評価ロジックのフォルダ内の`main.sh`を実行する

## 「依存 OSS」による「指定 OSS の発展」への貢献度を分析

### 概要

- 「指定 OSS が使用している（依存している）GitHub OSS」による「指定 OSS の発展」への貢献度を分析
- 実装をシンプルにするために、各依存ライブラリごとに恣意的な数値を入力して評価する
  - 今後は静的解析や他の指標を指標して評価できるようにしたい

### 使い方

```shell
./main.sh [option] [path]
```

- path

  - `path`に、指定フォーマットの使用 OSS の一覧の JSON ファイルの PATH を指定する
  - その JSON ファイルの形式は、以下の形式であれば OK！
    ```json
    {
      "data":[
        {a},{b},{},...
      ]
    }
    ```

- オプション
  - `-d`,`--default`
    - デフォルト値を記載する
  - `-c`,`--calc`
    - 記載した貢献度で算出する

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
