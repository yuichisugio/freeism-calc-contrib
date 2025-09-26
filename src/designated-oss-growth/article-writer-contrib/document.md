# Article Writer Contribution

## 概要

- 記事を書くことによる、指定した OSS への貢献の度合い

## 記事の投稿先の対応しているプラットフォーム

- Zenn
  - 対応カラム
    - `title`の文字数と`body_letters_count`の合計
    - `liked_count`による重み付け
    - `bookmarked_count`による重み付け
    - `published_at`で、エポック秒による重み付け
    - `total_count`による希少性

## 仕様

## 工夫

1. ファイル・フォルダを「過程」or「貢献の種類」のどちらで分けるか
   1. `get-data`,`process-data`,`calc-contrib`などの過程
   2. `zenn`,`qiita`,`note`,`hatena`などの記事の投稿先の種類
   3. 結論
      1. 基本は種類で分ける。一つだけ選んでも、その実装が複雑になる場合はその対象のみ切り出して過程で分ける
2.
