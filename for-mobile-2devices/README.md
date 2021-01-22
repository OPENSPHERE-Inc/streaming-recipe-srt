## 0. 前提

本レシピでは、スマホから絵音を送る「モバイル配信」を行う場合の配信システムを構築したいと思います。
今回も SRT という聞きなれないプロトコルを駆使することで、低遅延かつ高品質で信頼性の高いシステムを目指します。

尚、スマートフォン、vMix、その他配信に関する基本的な知識、PCの知識があることを前提とします。

SRT に関する説明は、[「ビューイング配信システム」の記事](/posts/remotework001) を読んでいる前提として割愛します。

## 1. 要件定義

1. 出演者がスマートフォンから絵音を送信するモバイル配信。自撮りかそうでないかは問わない。
2. 出演者が 2 名。それぞれスマートフォン片手に配信に参加する。今回、出演者同士のリモート通話は考えない。
3. 配信オペレーターは 1 名、出演者とは別の場所（スタジオ）で配信を実施する。
4. 配信オペレーターからトークバックで出演者に指示を出せる。トークバックは配信には乗せないこと。
5. 出演者 2 名から、それぞれカメラ映像と音声を受け取って、スタジオで合成して配信する。
6. 出演者 2 名は自身が所有するスマートフォン（と配信機材）を使用する。運営から特別な機材を用意しない。

## 2. 用意するもの

### 2.1. スタジオ側

* [vMix（HD エディション以上）](https://www.vmix.com/)
* ポートフォーワーディング可能なポート番号 4 つ
* パスワード（10 文字以上 79 文字以下）
* アップロード・ダウンロード共に　100 Mbps 以上出る光インターネット回線

### 2.2. 出演者側

* Larix Broadcaster
* カメラ搭載スマートフォン（Android 9+ を推奨）
* モバイルデータ回線（4G 以上）
* その他モバイル配信機材（ジンバル等）

## 3. システム図

![Picture.1](images/remotework035.jpg?raw=true)

## 4. Larix Broadcaster とは

[Larix Broadcaster](https://play.google.com/store/apps/details?id=com.wmspanel.larix_broadcaster&hl=en_US&gl=US)とは、
ロシアのSoftvelum LLC社が開発したフリーのスマホ向け配信アプリです。
Android 及び iOS 版があります（Android版がお勧め）。
RTMP での配信の他、SRT 等や RIST 等、先進的なプロトコルに対応しているのが特徴です。
また、hevc(h.265)、Adaptive Bitrate・Framerate、Background Streaming（Androidのみ）、外部Camera（Androidのみ）、Talkback（最近追加された）等、
実際の運用上で必要と考えらえれる便利機能を搭載しているのも利点です。

（スクショ入れる）

今回は、この Larix Broadcaster と SRT を組み合わせることで、高品質な配信システムを構築します。
しかも、くそ高い機材を使用せずに、です。

## 5. スタジオ側の仕込み

### 5.1. ポートフォーワーディングの設定

出演者からは合計 2 セットの絵音を受け取り、更に 1 本（2名とも同じ内容）のトークバックを返しますから、ポート番号を3つ決めてください。
ここでは `10001`, `10002`, `10003`, `10004` とします。

出演者A に `10001`（絵音受信用）<br />
出演者B に `10002`（絵音受信用）<br />
両者向けのトークバックに `10003` を割り当てるとし、それぞれ出演者に渡してください。<br />

ポート番号を決めたら、SRT を受信するPCに対して UDP でポートフォーワーディングを設定してください。
ポートフォーワーディング設定の仕方は、お使いのブロードバンドルーターのマニュアルを参照するか、ネットワーク担当者に問い合わせてください。

### 5.2. vMix の設定

SRT を受信する Input は2つ必要です。
上記で設定した「絵音受信用」の 2 つのポート番号について、それぞれ「Stream / SRT」で Input を作成してください。

「Add Input」→「Stream / SRT」を開いてください

| 項目                   | 設定値                           |
| -------------------- | ----------------------------- |
| Stream Type          | SRT (Listener)                |
| Port                 | 10001                         |
| Latency (ms)         | 240 ※単位ミリ秒          |
| Decoder Delay (ms)   | 0                             |
| Passphrase           | 10文字以上79文字以下のパスワード。出演者側の Larix Broadcaster に同じものを設定 |
| Key Length           | 変更不要                          |
| Stream ID            | 空欄のまま                         |
| Use Hardware Decoder | チェック入れる                       |

![Picture.2](images/remotework003.jpg?raw=true)

同じ手順で、もう1つ分ポート番号を「10003」変えて作成してください。

次に、トークバック用の SRT 出力を設定してください。
そのために、Audio Outputs で二つの Bus Output を有効にします。

「Settings」→「Audio Outputs」で、「A」を「Enabled」に変更してください。
即ち「Bus A」がトークバック用 Output となります。

（スクショ入れる）

更に「Settings」→「Outputs / NDI / SRT」→「3 Output」→「⚙」を開いて、以下の様に設定してください。

（スクショ入れる）

| 項目 | 設定値 |
| --- | --- |
| Audio Channels | BusA |
| Resolution | SD |
| Enable SRT | チェック入れる |
| Type | Listener |
| Port | 10002 |
| Latency | 240 ※単位ミリ秒 |
| Passphrase | 10文字以上79文字以下のパスワード。出演者側の Larix Broadcaster に同じものを設定 |
| Key Length | 16 |
| Use Hardware Encoder | チェック入れる |
| Use Low Power Encoder | チェック入れる |

（スクショ入れる）

更に「Quality」→「⚙」を開き、以下の様に設定してください。

| 項目 | 設定値 |
| --- | ----- |
| Codec | h.264 |
| Bitrate (kbps) | 128 |
| Audio→Bitrate (kbps) | 128 |

トークバック Output では、
映像を使用しないので、なるたけ低いビットレートにしてください。

（スクショ入れる）

次に、BusA にトークバックのみを送るために、Audio Input でマイク Input を作り、BusA のみ出力に設定してください。

（スクショ入れる）

最後に、「Settings」→「Outputs / NDI / SRT」→「3 Output」で、上記で選択した Audio Input を指定してください。
Audio Input の真っ黒な絵を 3 Output の映像として流用します（Audio は「Audio Channels」で指定済）。

（スクショ入れる）

以上で、スタジオからトークバックを出演者のスマートフォンに送る準備ができました。

## 6. 出演者側の仕込み

### 6.1. Larix Broadcaster のインストール

Larix Broadcaster をインストールしてください。
iOS版もあるのですが、ここでは筆者が推奨する Android 版を使用する前提で説明します。

Google Play を開いて Larix Broadcaster で検索をしてください。
見つかったらインストールを行います。

（スクショ入れる）

### 6.2. Larix Broadcaster の設定

インストールした Larix Broadcaster を起動してください。

#### 6.2.1. 接続の追加


