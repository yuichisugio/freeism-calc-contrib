# GitHub Developer Contribution

- [GitHub Developer Contribution](#github-developer-contribution)
  - [概要](#概要)
  - [使い方](#使い方)
    - [リポジトリ全体で初回のみ](#リポジトリ全体で初回のみ)
    - [処理を実行](#処理を実行)
    - [分析結果を削除したい場合](#分析結果を削除したい場合)
  - [出力形式](#出力形式)
    - [出力される形式は以下](#出力される形式は以下)
    - [表示するカラムは以下](#表示するカラムは以下)
    - [JSON 形式](#json-形式)
    - [CSV 形式](#csv-形式)
  - [今後追加したい内容](#今後追加したい内容)
  - [評価軸を追加・削除・変更したい場合](#評価軸を追加削除変更したい場合)
  - [Rate Limit 対策](#rate-limit-対策)
  - [貢献度の算出方法](#貢献度の算出方法)
    - [概要](#概要-1)
    - [各指標ごとの計算式](#各指標ごとの計算式)
      - [貢献の実施期間](#貢献の実施期間)
      - [作業量](#作業量)
      - [参加者からの評価](#参加者からの評価)
      - [対応速度](#対応速度)
      - [タスクの種類](#タスクの種類)
        - [プルリクエスト](#プルリクエスト)
        - [Issue](#issue)
        - [Discussions](#discussions)
        - [コミット](#コミット)
        - [others](#others)
    - [必要なカラム](#必要なカラム)
      - [Star](#star)
      - [Fork](#fork)
      - [Watch](#watch)
      - [Pull Request](#pull-request)
      - [Commit](#commit)
      - [Issue](#issue-1)
      - [Discussions](#discussions-1)
  - [工夫したポイント](#工夫したポイント)
  - [改善点](#改善点)

## 概要

- GitHub リポジトリの URL で指定したライブラリに貢献した開発者の一覧と貢献度を算出するツール

## 使い方

### リポジトリ全体で初回のみ

1. <a href="https://cli.github.com/" target="_blank" rel="noopener noreferrer">GitHub CLI(`gh`)</a>のインストール
2. <a href="https://cli.github.com/manual/gh_auth_login" target="_blank" rel="noopener noreferrer">`gh auth login`</a>でログイン
3. <a href="https://stedolan.github.io/jq/download/" target="_blank" rel="noopener noreferrer">`jq`</a>をインストール
4. `gh`に、権限を付与
   ```shell
   gh auth refresh --scopes read:user
   ```
5. シェルで、以下を実行
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
    - csv をスプシにコピペして、他の依存 OSS の貢献などと組み合わせて依存 OSS と開発者の貢献度の一覧を表示したい
    - また、無料主義アプリにそのままアップロードできるようにしたい
2.  JSON 形式

### 表示するカラムは以下

1.  データ取得元サービス名
1.  データ取得元ユーザー名
1.  データ取得元ユーザー ID
    - 名前は変わる可能性があるため
1.  ユーザーごとの貢献度
1.  ファイル作成日
1.  タスク名
    - オプション付きの場合に表示する
1.  データ取得元タスク ID
    - オプション付きの場合に表示する
1.  各重み付けの値
    - オプション付きの場合に表示する
1.  タスクごとの貢献度
    - オプション付きの場合に表示する
1.  タスクの実施日
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
1. ステータス変更の差分を算出する
   - `updatedAt`などを見て、プルリクエストのステータスが変わっているものだけ、以前のデータからの差分を算出したい
   - タスクの算出内容も知りたいため、以前のデータは`vervose`で出力が必須。

## 評価軸を追加・削除・変更したい場合

1. `./src/designated-oss-growth/github-developer-contrib/get-data`フォルダ直下に、新規ファイルを作成して、新しくデータを取得する処理を入れる
1. `./src/designated-oss-growth/github-developer-contrib/process-data`に、フォルダ直下に、新規ファイルを作成して、新しくデータの加工処理を入れる
1. `./src/designated-oss-growth/github-developer-contrib/calc-weighted`フォルダ直下に、重み付けの値を算出する処理を追加実装する
1. `./src/designated-oss-growth/github-developer-contrib/calc-contrib`に、貢献度を算出する処理を入れる

## Rate Limit 対策

- 基本は以前の取得分に追加して取得する使い方だと思うが、RateLimit 対策は後々実装したい

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
     - コミット・プルリクエストについては、`git commit`した日を実行日とする

#### 作業量

- 説明

  - 作業量で重みづけ
  - 作業量は、「コードの追加・削除の行数」、「コメントの追加・削除の行数」で評価する
  - `x`が行数 or コメントの文字数
  -
  - 無駄に冗長な場合は、バッドマークの絵文字を付けてマイナスに重み付けされるので良さげな長さになるはず

- 計算式

  - コード行数
    $$f(a, b) = \begin{cases} 0.1x & (y \geq 1) \\ 1 & (y \lt 1)\end{cases}$$
  - コメントの文字数
    $$f(a, b) = \begin{cases} 0.05x & (y \geq 1) \\ 1 & (y \lt 1)\end{cases}$$

- 対応タスク
  - プルリク
    - 作成者
      - プルリクの作成者のコード行数(commit ごとにカウントする`addictions`,`deletions`)
      - プルリクの作成者による作成時のコメントの文字数
    - レビュー時
      - プルリクのレビュー時のコード行数
      - プルリクのレビュー時のコメントの文字数
    - コメント
      - プルリクの作成者以外によるコメントの文字数
      - プルリクの作成者以外によるコード行数
  - Issue
    - Issue のコメントの文字数
  - Discussions
    - Discussions のコメントの文字数
  - コミット
    - コミットのコード行数
    - コミットの`git commit`のコメントの文字数

#### 参加者からの評価

- 説明

  - リアクション数
  - 👎 バッド`b`は、一つにつき`0.1`(初期値・自由に変更可能)
  - バッド以外`a`は、一つにつき`0.1`(初期値・自由に変更可能)
  - `y`が 0 以下でも、マイナスのままにして、ユーザー合算の時に他のタスクにも影響が出るようにしたい
  - discussions の`upvoteCount`もグッドとしてカウントしたい

- 計算式

  - いきなり、$f(a, b) =0.1a - 0.1b$で計算すると$a$が`0`(リアクションなし)の場合にすべての評価軸の結果を掛け算する際の貢献度が`0`になる。<br>なので、$a$が`0.1`以下の場合は、`0.1`にしてから、$a$と$b$を計算する。<br>小数を掛け算して貢献度の桁が少なくなるのは許容。リアクションの重み付けは少なくしたい。
    $$f(a) =\begin{cases} 0.1a & (y \geq 0.1) \\0.1 & (y \lt 0.1 )\end{cases}$$
    $$f(b) =-0.1b$$
    $$f(a,b) =f(a)+f(b)$$

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
      - Pull Request 作成から、リアクションするまでの日数
      - Pull Request 作成から、ラベル付けするまでの日数
      - Pull Request 作成から、レビュワー担当者アサインまでの日数
      - Pull Request 作成から、プルリクエスト担当者のアサインまでの日数
  1.  Discussions
      - Discussions 作成から、コメントまでの日数
      - Discussions 作成から、リアクションするまでの日数
      - ※「Discussions 作成からステータス変更」は、議論を十分する時間がなくなり望まない結果になるので算出しない。

#### タスクの種類

- 説明
  - GitHub API **から取得できるタスクの重み付け**

##### プルリクエスト

1. プルリクエストの作成（`Merged`、`Approved`）
   - `approved`は承認済みだけどマージはされていない状態
   - `3`
2. プルリクエストの作成（`Draft`,`Rejected`,`Open`,`Pending`,`Changes requested`）
   - `0`
   - 不要な AI コードばかりを送り付けるハックを防ぐため
3. プルリクエストにコメント投稿
   - `1`
4. プルリクエストをマージ
   - `2`
5. プルリクエストをレビューして、`Approved` or `Rejected`
   - `3`
6. プルリクエストにラベル付け
   - `1`
7. プルリクエストの作成担当者のアサイン
   - `1`
8. プルリクエストのレビュー担当者のアサイン
   - `1`
9. プルリクエストにリアクションをつける
   - どんな絵文字でも 1 つ以上つけたら貢献。2 つ以上つけても合算しない。
   - `1`

##### Issue

1. Issue 作成（`CLOSED` - `COMPLETED`）
   - `3`
2. Issue 作成（`CLOSED` - `DUPLICATE`,`NOT_PLANNED`,`REOPENED`）
   - `1`
3. Issue 作成（`OPEN`）
   - `2`
4. Issue にコメント
   - `1`
5. Issue のステータスを変更（Open・Closed=Completed/Not planned）
   - `1`
6. Issue にラベル付けをする
   - `1`
7. 担当者をアサイン（アサインする側）
   - `1`
8. Issue にリアクションをつける
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
   - API で、`timelineItems`が無いため取得できない
1. Discussions にカテゴリー分けをする
   - `1`
1. Discussions に回答する
   - `3`
1. Discussions の回答を決定する
   - `3`
1. Discussions に投票する
   - 取得できる API がない

##### コミット

1. `main` ブランチへのコミット
   - 基本はプルリクエストで管理したい
   - GitHub API で、`branchProtectionRules` オブジェクトの`Require a pull request before merging` が`true`の場合は不要
   - コミットは、main ブランチに直接プッシュした場合のみカウントしたい
   - `2`
1. コミットへコメント
   - `1`
1. コミットへのコメントへリアクション
   - `1`

##### others

- ※API の Rate Limit 的にデータは取得しない可能性もある

1. Star する
   - `1`
1. Fork する
   - `1`
   - fork 回数が何度あっても重複カウントしない
1. Watch する
   - `1`
1. スポンサーをする
   - 一旦は、GitHub Sponsors のみ対象
   - `owner`,`funding.yaml`記載のユーザー・組織に対して、リポジトリ関係なくスポンサーしている人たちが対象。このリポジトリに限らずとも支援していたら評価する
   - `50`

### 必要なカラム

#### Star

- 押した人のユーザー名
- 押した人のユーザー ID
- 押した日
  - 期間指定できないため`--paginate`を使用せず、手動ページネーションで期間のみを掲載してページネーションの for 文を止める処理を入れている

#### Fork

- 押した人のユーザー名
- 押した人のユーザー ID
- 押した日
  - 期間指定できないため`--paginate`を使用せず、手動ページネーションで期間のみを掲載してページネーションの for 文を止める処理を入れている

#### Watch

- 押した人のユーザー名
- 押した人のユーザー ID
- 押した日
  - カラムが存在しない。ソートもできないのでローカルで名前順に並び替えて差分を見るしかない？

#### Pull Request

- プルリク担当者
  - 割り振った人のユーザー名
  - 割り振った人のユーザー ID
  - 割り振った日
- レビュー担当者
  - 割り振った人のユーザー名
  - 割り振った人のユーザー ID
  - 割り振った日
- プルリクのコメント
  - コメント作成者のユーザー名
  - コメント作成者のユーザー ID
  - コメント作成日
  - コメントの文字数
- プルリクの作成
  - プルリク作成者のユーザー名
  - プルリク作成者のユーザー ID
  - プルリク作成日
  - コードの追加・削除の行数
  - コメントの文字数
- プルリクのマージ担当者
  - ステータス変更者のユーザー名
  - ステータス変更者のユーザー ID
  - ステータス変更日
  - 変更したステータスの内容
- プルリク作成のリアクション
  - リアクション作成者のユーザー名
  - リアクション作成者のユーザー ID
  - リアクション作成日
  - リアクションの種類（バッドか否か）
- プルリクへのコメントのリアクション
  - リアクション作成者のユーザー名
  - リアクション作成者のユーザー ID
  - リアクション作成日
  - リアクションの種類（バッドか否か）

#### Commit

- 取得項目
  - コミット日
  - コミット者のユーザー名
  - コミット者のユーザー ID
  - コード行数
  - コメントの文字数

#### Issue

- ラベル
  - 割り振った人のユーザー名
  - 割り振った人のユーザー ID
  - 割り振った日
- 担当者
  - 割り振った人のユーザー名
  - 割り振った人のユーザー ID
  - 割り振った日
- Issue の作成
  - Issue 作成者のユーザー名
  - Issue 作成者のユーザー ID
  - Issue 作成日
  - コメントの文字数
- Issue 提案へのコメント
  - コメント作成者のユーザー名
  - コメント作成者のユーザー ID
  - コメント作成日
  - コメントの文字数
- Issue のステータス変更
  - ステータス変更者のユーザー名
  - ステータス変更者のユーザー ID
  - ステータス変更日
- Issue 作成のリアクション
  - リアクション作成者のユーザー名
  - リアクション作成者のユーザー ID
  - リアクション作成日
  - リアクションの種類（バッドか否か）
- Issue コメントのリアクション
  - リアクション作成者のユーザー名
  - リアクション作成者のユーザー ID
  - リアクション作成日
  - リアクションの種類（バッドか否か）

#### Discussions

- カテゴリー
  - 割り振った人のユーザー名
  - 割り振った人のユーザー ID
  - 割り振った日
- ラベル
  - 割り振った人のユーザー名
  - 割り振った人のユーザー ID
  - 割り振った日
- 投票
  - 投票者のユーザー名
  - 投票者のユーザー ID
  - 投票日
- 議題提案の作成
  - 作成者のユーザー名
  - 作成者のユーザー ID
  - 作成日
  - コメントの文字数
- 議題提案へのコメント
  - 作成者のユーザー名
  - 作成者のユーザー ID
  - 作成日
  - コメントの文字数
- 議題提案へのリアクション
  - 作成者のユーザー名
  - 作成者のユーザー ID
  - 作成日
  - リアクションの種類（バッドか否か）
- 議題提案へのコメントへのリアクション
  - 作成者のユーザー名
  - 作成者のユーザー ID
  - 作成日
  - リアクションの種類（バッドか否か）

## 工夫したポイント

1. User オブジェクトの`id`フィールドは、`MDQ6SIOlcjg0MzI4Ng==`と`U_kgDOCihAMg`のような形式があるので、以下オプションで統一して取得している
   - `--header X-Github-Next-Global-ID:1`オプションを指定することで、新しい形式を取得できる
1. 何かしらの ID で突合できるように、得られる ID 系フィールド全てを取得する
1. Issue のラベル付けの作業で貢献として認める仕様
   - 各 Issue ごとに、現在ついている全てのラベルをそれぞれラベル付けした最新の日・最新の人のみを貢献として認める
1. プルリクの`reviewRequests`は、レビュー担当者としてアサインされながらレビューが未完了の人のみを返す。なので、全員が完了済みの人も欲しい場合は`ReviewRequestedEvent`と`ReviewRequestRemovedEvent`を使用する必要がある
1. `Discussion`でも`labels`はあるが、`timelineItems`が存在しないため、ラベル付けしたひとを取得できないので貢献度としては算出できない
1. `Pull Request`オブジェクトの`timelineItems`フィールドの`MERGED_EVENT`の後に必ず`CLOSED_EVENT`が実行されているので、`MERGED_EVENT`は取得しない
   1. ステータス変更(reject or merged)した人のタスクは、`CLOSED_EVENT`だけですべて拾える
1. discussion の`answer`と`comment`は同じ扱いっぽい。
   - なので同じ人内で同じデータが`answer`と`comment`の両方で取得できてしまう。
   - また、`answer`に対して行った`reaction`や`reply`も、コメントに対してのタスクとしても出力されるので重複する
   - answer は comment の方を削除したい。answer は comment よりも重み付けしているため。
   - reaction や reply はどちらでも問題ないので、どちらかを削除したい。
   - `integrate_processed_files`関数に処理を実装した
1. `watch`は`createdAt`が存在しない。期間で区切っても毎回全て出力される。
   - 貢献と認めたくない場合は、`weighting.jsonc`で`0`にすれば OK
1. `Release`は、バッドリアクションが無く、グッドリアクションしか押せない・選べない

## 改善点

1. `nodes`クエリのテスト
   - `nodes`クエリでノード ID をバッチで取得して、リクエストごとの数ではなく 100 分の 1 の数の消費に抑えたい
   - 現在は`node`クエリで一つずつしか取得しておらず、rateLimit のポイントを多く消費してしまう実装になっている
   - ページネーションの設計が複雑になるので、プルリクや Issue の label 数など現実的に 50 個以上つかない場合で使用できそう
1. ①`Pull Request`の`id`フィールド(node の id)の取得と ②`id`を使用して`node`クエリで情報を取得する場合に、① は期間外だが、② は期間内のデータがあったときに、② のデータを確実に取得できるように、すべての ① のデータを取得しておく設計
   - 今後実装したい
   - 目的は期間を指定して取得することじたいではなく、データの漏れを無くすことなため、`-s`,`-un`で期間の漏れがなく指定できれば、すべてのデータを取得できるので、一旦は簡潔な設計にするため後回し
1. アサインイベント以外は jq 側で最新のデータのみ抽出するのであれば、`timelineItems`のそれぞれのイベントは`last:1`で良さそう
1. `timelineItems`で、別イベントも取得してしまっているので、一緒のクエリで取得して、データ加工時に、`__typename`で分けたほうが良さそう
1. get-data などの処理を並列で実行したい
