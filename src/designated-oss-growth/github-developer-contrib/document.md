# developer contribution

## 概要

## 使い方

### リポジトリ全体で初回のみ

1. [GitHub CLI(`gh`)](https://cli.github.com/)のインストール
1. [`gh auth login`](https://cli.github.com/manual/gh_auth_login)でログイン
1. [jq](https://stedolan.github.io/jq/download/) をインストール
1. シェルで、以下を実行
   ```shell
   git clone https://github.com/yuichisugio/freeism-contribution-calculate.git
   ```
   ※一部で、初回のみ GitHub の Personal Access Token が必要な場合がある。その場合は、各評価軸の`document.md`に記載

### 処理を実行

1. 分析する場合
   ```shell
   ./main.sh [option] [path]
   ```

### 分析結果を削除したい場合

1. シェルで、以下を実行
   ```shell
   ./reset.sh [オプション]
   ```
   - オプションなしで、`results`フォルダのデータをすべて削除
   - `-p`or`-pull-request`で`pull-request`フォルダのみ削除
   - `-p`or`-issue`で`issue`フォルダのみ削除
   - `-m`or`-main`で`main`フォルダのみ削除

## 出力形式

### 出力される形式は以下

1.  CSV 形式
1.  JSON 形式
    - 後々対応

### 表示するカラムは以下

1.  データ取得元サービス名
1.  データ取得元ユーザー名
1.  データ取得元ユーザー ID
1.  タスク名
1.  データ取得元タスク ID
1.  タスクの貢献度
1.  貢献度の算出ロジック
1.  各重み付けの値
1.  メモ
1.  算出日

### JSON 形式

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

### CSV 形式

```csv
meta,createdAt,specified-oss
meta,specified-oss,
```

## 今後追加したい内容

1. 期間を指定して貢献度の算出ができる仕組み
   - API 制限的に一度に取得できる数に限りがあるため、以前の分析に追加で取得したい
   - インクリメンタルなデータ取得・貢献度の分析を行いたい
1. 以前の分析を使用して、足りない部分のみデータ取得する仕組み
   - API 制限的に一度に取得できる数に限りがあるため、以前の`./results`フォルダの結果を使用したい
1. Zenn など他 API からも情報を取得して貢献度を算出する

## 評価軸を追加・削除・変更したい場合

1. `./src`フォルダ直下に、
1. `./src/get-data`フォルダ直下に、新規ファイルを作成して、新しくデータを取得する処理を入れる
1. `./src/data-process`に、フォルダ直下に、新規ファイルを作成して、新しくデータの加工処理を入れる
1. `./src/calc-weighted`フォルダ直下に、重み付けの値を算出する処理を追加実装する
1. `./src/calc-contrib/calc-amount-contrib.sh`に、貢献度を算出する処理を入れる

## 貢献度の算出方法

### 概要

#### 貢献度の算出の流れ

1.  各タスクごとに、それぞれの評価軸の視点で貢献度を算出する
1.  全ての評価軸の貢献度を掛け算して、タスクごとの貢献度を算出
1.  タスクごとの貢献度を、ユーザーごとに合算する

#### 評価軸の一覧

1.  貢献の実施期間
1.  作業量
1.  参加者からの評価
1.  対応速度
1.  タスクの種類

### 各指標ごとの計算式

#### 貢献の実施期間

- 説明

  - 初期に貢献するほど、プロジェクトを見つけて発展させる貢献度は大きいので評価したい
  - 「ライブラリ作成日」から数えた日数を`x`に入れる。

- 計算式
  $$f(a, b) =\begin{cases} y=-x + 3650 & (y \geq 1) \\1 & (y \lt 1)\end{cases}$$

- 対応タスク
  1. 全てのタスク

#### 作業量

- 説明

  - 作業量で重みづけ
  - 作業量は、「コードの追加・削除の行数」、「コメントの追加・削除の行数」で評価する
  - `x`が行数
  - 無駄に冗長な場合は、バッドマークの絵文字を付けてマイナスに重み付けされるので良さげな長さになるはず

- 計算式
  $$f(a, b) = \begin{cases} 0.1x & (y \geq 1) \\ 1 & (y \lt 1)\end{cases}$$

- 対応タスク
  - プルリク
  - イシュー
  - コメント
  - Discussions

#### 参加者からの評価

- 説明

  - リアクション数
  - 👎 バッド`b`は、一つにつき`-0.1`
  - バッド以外`a`は、一つにつき`0.1`
  - `y`が 0 以下の場合は`0`にする

- 計算式
  $$f(a, b) =\begin{cases}0.1a - 0.1b & (y \geq 1) \\1 & (y \lt 1)\end{cases}$$

- 対応タスク
  - pullRequest
  - Issue
  - Comment
  - Discussions

#### 対応速度

- 説明

  - 各タスクごとの対応速度で重み付け
  - 「作成日」から「実施日」までの「日数`x`」が短いほど評価を高める。

- 計算式
  $$f(a, b) =\begin{cases} -x + 30 & (y \geq 1) \\1 & (y \lt 1)\end{cases}$$

- 対応タスク
  1.  Issue 作成から対応するプルリクエスト作成日までの対応速度
  1.  プルリク作成からマージ or リジェクトまでの期間
  1.  c

#### タスクの種類

- 説明
  - GitHub API から取得できるタスク全部（プルリクエスト・Issue・ドキュメント整備・など）

##### プルリクエスト

1. プルリクエストの作成（Merged・Approved）
   - `approved`は承認済みだけどマージはまだ
1. プルリクエストの作成（Closed）
1. プルリクエストの作成（Open・Draft・Pending・Changes requested）
1. プルリクエストにコメント投稿
1. プルリクエストをマージ
1. プルリクエストをレビューして、Approved or Closed
1. プルリクエストにラベル付け

##### イシュー

1. イシュー作成（Closed - Completed）
1. イシュー作成（Closed - Not planned）
1. イシュー作成（Open）
1. イシューにコメント
1. イシューのステータスを変更（Open・Closed）
1. イシューにラベル付けをする
1. 担当者をアサイン（アサインする側）

#### ディスカッション

1. ディスカッションの作成
1. コメントを投稿
1. コメントにリアクション
1. ラベル付けをする
1. カテゴリー分けをする

##### スポンサー

1. スポンサー（大・単発）
1. スポンサー（中・単発）
1. スポンサー（小・単発）
1. スポンサー（大・毎月）
1. スポンサー（中・毎月）
1. スポンサー（小・毎月）

##### コミット

1. main ブランチへのコミット
   - 基本はプルリクエストで管理したい
   - GitHub API で、branchProtectionRules オブジェクトが Require a pull request before merging が`true`の場合は、不要
   - コミットは、main ブランチに直接プッシュした場合のみカウントしたい
