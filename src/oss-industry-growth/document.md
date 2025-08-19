# 評価軸「OSS 業界全体の発展」

## 概要

- 評価軸「OSS 業界全体の発展」に貢献した対象を評価をする仕組み
- 評価する対象は、人間・OSS 等さまざま。

## 評価ロジックの種類

1. 「GitHub OSS」の貢献度を独自の指標の組み合わせ
1. OpenRank

## 評価ロジックごとの説明

### 「GitHub OSS」の貢献度を分析する場合

#### 概要

-

#### 必要な準備

- [scorecard](https://github.com/ossf/scorecard?tab=readme-ov-file 'scorecard github url')を使用しているため、その環境構築が必要
  1. scorecard をインストール
     ```shell
     brew install scorecard
     ```
  2. Github の Personal Access Token を取得
     - 権限は、classic にして、public_repo などにチェック。read-only の権限だけで OK

## 貢献度を分析するロジック

### OpenRank

#### 概要

- [OpenRank](https://open-digger.cn/en/docs/user-docs/metrics/openrank)による評価
- 以下のように取得したいリポジトリを URL 内で指定すると、OpenRank が JSON で取得できる
  - https://oss.open-digger.cn/github/X-lab2017/open-digger/community_openrank.json
  - https://oss.open-digger.cn/github/X-lab2017/open-digger/openrank.json
