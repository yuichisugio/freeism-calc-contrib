# 評価軸「OSS 業界全体の発展」

## 概要

- 評価軸「OSS 業界全体の発展」に貢献した対象を評価をする仕組み
- 評価する対象は、人間・OSS 等さまざま。

## 評価ロジックの種類

1. 「GitHub OSS」の貢献度を分析

## 評価ロジックごとの特殊な準備

### 「GitHub OSS」の貢献度を分析する場合
- [scorecard](https://github.com/ossf/scorecard?tab=readme-ov-file "scorecard github url")を使用しているため、その環境構築が必要
    1. scorecardをインストール
        ```shell
        brew install scorecard
        ```
    2. GithubのPersonal Access Tokenを取得
        - 権限は、classic にして、public_repoなどにチェック。read-onlyの権限だけでOK

## 貢献度を分析するロジック

### 「GitHub OSS」の貢献度を分析

1. セキュリティ
   - [scorecard](https://github.com/ossf/scorecard?tab=readme-ov-file "scorecard github url")を使用している
