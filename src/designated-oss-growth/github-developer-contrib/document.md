# developer contribution

## 概要

- GitHub リポジトリの URL で指定したライブラリに貢献した開発者の一覧と貢献度を算出するツール

## 使い方

### リポジトリ全体で初回のみ

1. <a href="https://cli.github.com/" target="_blank" rel="noopener noreferrer">GitHub CLI(`gh`)</a>のインストール
1. <a href="https://cli.github.com/manual/gh_auth_login" target="_blank" rel="noopener noreferrer">`gh auth login`</a>でログイン
1. <a href="https://stedolan.github.io/jq/download/" target="_blank" rel="noopener noreferrer">`jq`</a>をインストール
1. シェルで、以下を実行
   ```shell
   git clone https://github.com/yuichisugio/freeism-calc-contrib.git
   ```

### 処理を実行

1. 分析する場合
   - `[path]`は、GitHub のリポジトリ URL をそのまま渡せば OK
   ```shell
   ./main.sh [path] [option]
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

### 表示するカラムは以下

1.  データ取得元サービス名
1.  データ取得元ユーザー名
1.  データ取得元ユーザー ID
    - 名前は変わる可能性があるため
1.  タスクの貢献度
1.  ファイル作成日
1.  タスク名
    - オプション付きの場合に表示する
1.  データ取得元タスク ID
    - オプション付きの場合に表示する
1.  各重み付けの値
    - オプション付きの場合に表示する

### JSON 形式

```json
{
	"meta": {
		"createdAt": "2025-08-20",
		"analysisPeriod": {
			"start": "2025-08-20",
			"end": "2025-08-20"
		},
		"specified-oss": {
			"host": "github.com",
			"owner": "ryoppippi",
			"Repository": "ccusage",
			"url": "https://github.com/ryoppippi/ccusage"
		}
	},
	"data": [
		{
			"host": "github.com",
			"hostUsername": "aaa",
			"hostUserId": "1234567",
			"contribution": 15
		},
		{
			"host": "github.com",
			"hostUsername": "bbb",
			"hostUserId": "1234567",
			"contribution": 99995500
		}
	]
}
```

- `-vervose`, `-v` or `-detail`,`-d`のオプションをつけた場合は、各ユーザー内のタスクごとに以下が追加
  - 後々の開発
  ```json
  "task": {
  	"taskName":"abc",
  	"taskId":"abc",
  	"executedDate":"2025-08-20",
  	"weighting":1
  }
  ```

### CSV 形式

```csv
createdAt,analysisStart,analysisEnd,specifiedOssHost,specifiedOssOwner,specifiedOssRepository,specifiedOssUrl,host,hostUsername,contribution,hostUserId
2025-08-20,2025-08-20,2025-08-20,github.com,ryoppippi,ccusage,https://github.com/ryoppippi/ccusage,github.com,aaa,15,gerhtsymdgh
2025-08-20,2025-08-20,2025-08-20,github.com,ryoppippi,ccusage,https://github.com/ryoppippi/ccusage,github.com,bbb,99995500,wqewghare
```

## 今後追加したい内容

1. 期間を指定して貢献度の算出ができる仕組み
   - API 制限的に一度に取得できる数に限りがあるため

## 評価軸を追加・削除・変更したい場合

1. `./src/get-data`フォルダ直下に、新規ファイルを作成して、新しくデータを取得する処理を入れる
1. `./src/data-process`に、フォルダ直下に、新規ファイルを作成して、新しくデータの加工処理を入れる
1. `./src/calc-weighted`フォルダ直下に、重み付けの値を算出する処理を追加実装する
1. `./src/calc-contrib/calc-amount-contrib.sh`に、貢献度を算出する処理を入れる

## 貢献度の算出方法

### 概要

- 貢献度の算出の流れ

  1.  各タスクごとに、それぞれの評価軸の視点で貢献度を算出する
  1.  全ての評価軸の貢献度を掛け算して、タスクごとの貢献度を算出
  1.  タスクごとの貢献度を、ユーザーごとに合算する

- 評価軸の一覧
  1.  貢献の実施期間
  1.  作業量
  1.  参加者からの評価
  1.  対応速度
  1.  タスクの種類

### 各指標ごとの計算式

#### 貢献の実施期間

- 説明

  - 初期に貢献するほど、プロジェクトを見つけて発展させる貢献度は大きいので評価したい。
  - 「ライブラリ作成日」から数えた日数を`x`に入れる。

- 計算式
  $$f(a, b) =\begin{cases} y=-x + 3650 & (y \geq 1) \\1 & (y \lt 1)\end{cases}$$

- 対応タスク
  1. 「タスクの種類」に記載の全てのタスク

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
    - プルリクの作成時のコード行数
    - プルリクの作 成者による作成時のコメント行数
    - プルリクの作成者以外によるコメント行数
  - Issue
    - Issue のコメント行数
  - Discussions
    - Discussions のコメント行数
  - コミット
    - コミットのコード行数
    - コミットの`git commit`のコメント行数

#### 参加者からの評価

- 説明

  - リアクション数
  - 👎 バッド`b`は、一つにつき`0.1`
  - バッド以外`a`は、一つにつき`0.1`
  - `y`が 0 以下でも、マイナスのままにして、ユーザー合算の時に他のタスクにも影響が出るようにしたい

- 計算式
  $$f(a, b) =0.1a - 0.1b$$

- 対応タスク
  - Pull Request
    - Pull Request のコード提案のリアクション数
    - Pull Request のコード提案に返信したコメントのリアクション数
  - Issue
    - Issue の議題提案のリアクション数
    - Issue の議題提案に返信したコメントのリアクション数
  - Discussions
    - Discussions の提案のリアクション数
    - Discussions の提案に返信したコメントのリアクション数

#### 対応速度

- 説明

  - 各タスクごとの対応速度で重み付け
  - 「作成日」から「実施日」までの「日数`x`」が短いほど評価を高める。

- 計算式
  $$f(a, b) =\begin{cases} -x + 30 & (y \geq 1) \\1 & (y \lt 1)\end{cases}$$

- 対応タスク

  1.  Issue
      - Issue 作成から、コメントまでの日数
      - Issue 作成から、ステータス変更までの日数
      - Issue 作成から、リアクションするまでの日数
      - Issue 作成から、ラベル付けするまでの日数
      - Issue 作成から、担当者のアサインまでの日数
  1.  Pull Request
      - Pull Request 作成から、`Rejected`or`Approved`or`Merged`までの日数
      - Pull Request 作成から、コメントまでの日数
      - Pull Request 作成から、ステータス変更までの日数
      - Pull Request 作成から、リアクションするまでの日数
      - Pull Request 作成から、ラベル付けするまでの日数
      - Pull Request 作成から、レビュワー担当者アサインまでの日数
      - Pull Request 作成から、プルリクエスト担当者のアサインまでの日数
  1.  Discussions
      - Discussions 作成から、コメントまでの期間
      - Discussions 作成から、リアクションするまでの日数
      - Discussions 作成から、ラベル付けするまでの日数
      - Discussions 作成から、カテゴリー分けまでの日数
      - Discussions 作成から、Voting までの日数
      - ※「Discussions 作成からステータス変更」は、議論を十分する時間がなくなり望まない結果になるので算出しない。

#### タスクの種類

- 説明
  - GitHub API から取得できるタスクの重み付け

##### プルリクエスト

1. プルリクエストの作成（Merged、Approved）
   - `approved`は承認済みだけどマージはまだ
   - `5`
1. プルリクエストの作成（`Draft`）
   - `0.5`
1. プルリクエストの作成（`Rejected`,`Open`,`Pending`,`Changes requested`）
   - `3`
1. プルリクエストにコメント投稿
   - `1`
1. プルリクエストをマージ
   - `2`
1. プルリクエストをレビューして、Approved or Rejected
   - `3`
1. プルリクエストにラベル付け
   - `1`
1. プルリクエストの担当者のアサイン
   - `1`
1. プルリクエストにリアクションをつける
   - どんな絵文字でも 1 つ以上つけたら貢献。2 つ以上つけても合算しない。
   - `1`

##### Issue

1. Issue 作成（Closed - Completed）
   - `3`
1. Issue 作成（Closed - Not planned）
   - `1`
1. Issue 作成（Open）
   - `2`
1. Issue にコメント
   - `1`
1. Issue のステータスを変更（Open・Closed=Completed/Not planned）
   - `1`
1. Issue にラベル付けをする
   - `1`
1. 担当者をアサイン（アサインする側）
   - `1`
1. Issue にリアクションをつける
   - どんな絵文字でも 1 つ以上つけたら貢献。2 つ以上つけても合算しない。
   - `1`

##### Discussions

1. Discussions の作成
   - `2`
1. Discussions にコメント
   - `1`
1. Discussions にリアクション
   - どんな絵文字でも 1 つ以上つけたら貢献。2 つ以上つけても合算しない。
   - `1`
1. Discussions にラベル付け
   - `1`
1. Discussions にカテゴリー分けをする
   - `1`
1. Discussions に投票する
   - `1`

##### コミット

1. `main` ブランチへのコミット
   - 基本はプルリクエストで管理したい
   - GitHub API で、`branchProtectionRules` オブジェクトの`Require a pull request before merging` が`true`の場合は不要
   - コミットは、main ブランチに直接プッシュした場合のみカウントしたい
   - `2`
