## 0. 前提

本レシピでは、スマートフォンから絵音を送る「モバイル配信」を行う場合の配信システムを構築したいと思います。
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
* イヤホン（トークバック・モニター用）と必要であれば [4極 3.5mm から 3極 3.5mm x 2 に変換する Y 字ケーブル](https://www.amazon.co.jp/dp/B01BV916AQ/ref=cm_sw_r_tw_dp_zHUcGbR8XHGNE)
* モバイルデータ回線（4G 以上）
* その他モバイル配信機材（グリップやジンバル等）

## 3. システム図

![Picture.1](images/remotework035.jpg?raw=true)

## 4. Larix Broadcaster とは

[Larix Broadcaster](https://play.google.com/store/apps/details?id=com.wmspanel.larix_broadcaster&hl=en_US&gl=US) とは、
ロシアのSoftvelum LLC社が開発したフリーのスマートフォン向け配信アプリです。
Android 及び iOS 版があります（Android版がお勧め）。
RTMP での配信の他、SRT 等や RIST 等、先進的なプロトコルに対応しているのが特徴です。
また、hevc(h.265)、Adaptive Bitrate・Framerate、Background Streaming（Androidのみ）、外部Camera（Androidのみ）、Talkback（最近追加された）等、
実際の運用上で必要と考えらえれる便利機能を搭載しているのも利点です。

![Picture.2](images/remotework051.jpg?raw=true)

今回は、この Larix Broadcaster と SRT を組み合わせることで、高品質な配信システムを構築します。
しかも高価な機材を使用せずに、です。

### Larix Broadcaster の使い方

![Picture.3](images/remotework052.jpg?raw=true)

1. 設定
2. マイクミュート・ミュート解除
3. 配信開始（配信中は「配信停止」）
4. フラッシュライト点灯・消灯
5. スナップショット撮影
6. フレームレート表示
7. 録画インジケーター（録画時間）
8. Talkback ONLINE/OFFLINE 表示
9. カメラフリップ（フロントカメラ⇔リアカメラ）
10. Audioレベルメーター
11. 配信インジケーター（送信先、ビットレート、転送量）
12. 画面ダブルタップでフォーカスモードを切り替え（Auto Focus⇔Focus to Infinity）
13. 画面ピンチイン・ピンチアウトでデジタルズームイン・アウト

## 5. スタジオ側の仕込み

### 5.1. ポートフォーワーディングの設定

出演者からは合計 2 セットの絵音を受け取り、更に 1 本（2名とも同じ内容）のトークバックを返しますから、ポート番号を3つ決めてください。
ここでは `10001`, `10002`, `10003` とします。

出演者A に `10001`（絵音受信用）<br />
出演者B に `10002`（絵音受信用）<br />
全出演者向けのトークバックに `10003` を割り当てるとし、それぞれ出演者に渡してください。<br />

ポート番号を決めたら、SRT を受信するPCに対して UDP でポートフォーワーディングを設定してください。
ポートフォーワーディング設定の仕方は、お使いのブロードバンドルーターのマニュアルを参照するか、ネットワーク担当者に問い合わせてください。

また、スタジオのグローバル IP アドレスを控えておいてください。
グローバル IP アドレスの調べ方は [こちら](https://www.google.com/search?q=IP+Checker) 。

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

![Picture.4](images/remotework003.jpg?raw=true)

同じ手順で、もう1つ分ポート番号を「10002」変えて作成してください。

次に、トークバック用の SRT 出力を設定してください。
そのために、Audio Outputs で Bus Output を 1 つ有効にします。

「Settings」→「Audio Outputs」で、「A」を「Enabled」に変更してください。
以降、「Bus A」はトークバック用 Output となります。

![Picture.5](images/remotework036.jpg?raw=true)


「Settings」→「Outputs / NDI / SRT」→「3 Output」で、「Source」を「Input300」に設定してください。
なぜこのような設定をするのかと言うと、トークバックでは映像を使用しない為で、
大抵は使用されないであろう一番後ろの 300 番 Input を指定し「常に真っ黒」にします。
更に→「⚙」を開いて、以下の様に設定してください。

![Picture.6](images/remotework037.jpg?raw=true)

| 項目 | 設定値 |
| --- | --- |
| Audio Channels | BusA |
| Alpha Channel | None |
| Resolution | SD |
| Enable SRT | チェック入れる |
| Type | Listener |
| Port | 10003 |
| Latency | 240 ※単位ミリ秒 |
| Passphrase | 10文字以上79文字以下のパスワード。出演者側の Larix Broadcaster に同じものを設定 |
| Key Length | 16 |
| Use Hardware Encoder | チェック入れる |
| Use Low Power Encoder | チェック入れる |

![Picture.7](images/remotework038.jpg?raw=true)

更に「Quality」→「⚙」を開き、以下の様に設定してください。

| 項目 | 設定値 |
| --- | ----- |
| Codec | h.264 |
| Bitrate (kbps) | 128 |
| Audio→Bitrate (kbps) | 128 |

トークバック Output では、
映像を使用しないので、**なるたけ低いビットレート**にしてください（仕様上、映像のみ OFF にはできない）

![Picture.8](images/remotework039.jpg?raw=true)

次に、一旦 Settings を閉じて vMix ウィンドウに戻り、
Audio Input でマイク Input を作り、Audio Mixer で「BusA へのみ出力」に設定してください。

![Picture.9](images/remotework040.jpg?raw=true)

以上で、スタジオからのトークバックを出演者のスマートフォンに送る準備ができました。
尚、これ以降にスタジオ側で特別な操作は必要なく、出演者側で適切な設定を行えば、常にトークバックが送信されます。

## 6. 出演者側の仕込み

### 6.1. スマートフォンのセットアップ

#### 6.1.1. 周辺機器の準備

**トークバックが配信に乗らない様に、必ずイヤホンを接続して聴くようにしてください。**
スマートフォン本体のマイクを生かしたい場合、マイク付きのイヤホンを接続すると接続機器が優先されてしまうので、
[4極 3.5mm から 3極 3.5mm x 2 に変換する Y 字ケーブル](https://www.amazon.co.jp/dp/B01BV916AQ/ref=cm_sw_r_tw_dp_zHUcGbR8XHGNE) を使用してください。

配信中はバッテリーの消費が激しいので、容量が大きめのモバイルバッテリーも準備し、いつでも給電できるようにしてください。

![Picture.10](images/remotework041.jpg?raw=true)

また、撮影がし易い様にグリップやジンバルを使用しましょう。

#### 6.1.2. 配信アプリ「Larix Broadcaster」の準備

次に、今回使用する配信アプリ、「Larix Broadcaster」をインストールしてください。
iOS版もあるのですが、ここでは筆者が推奨する Android 版を使用する前提で説明します。

Google Play を開いて Larix Broadcaster で検索をしインストールしてください。

![Picture.11](images/remotework042.jpg?raw=true)

#### 6.1.3. 本番中着信の防止

最後に、本番中に着信が来ると困りますから、[着信拒否](https://play.google.com/store/apps/details?id=org.litewhite.callblocker) などを利用して、
どの電話番号からでも着信しない様に設定してください。
最もお勧め出来るのは、配信専用のスマートフォン(*) を用意することです。

![Picture.12](images/remotework043.jpg?raw=true)

---
(*) 回線契約せず wifi 利用でも良いですが、[docomo のデータプラス](https://www.nttdocomo.co.jp/charge/dataplus-2/) 等のサービスを使うと、
データ通信専用のスマートフォンを、回線の追加契約なし（プランを共有したまま）で増やすことが出来ます。SIMの取り寄せが可能です。

### 6.2. Larix Broadcaster の設定

インストールした Larix Broadcaster を起動してください。
Larix Broadcaster では、以下に挙げる設定を行います。

1. 絵音送信先として、SRT 接続を追加
2. トークバック受信元として、SRT 接続を追加
3. Video の設定
4. Audio の設定
5. その他の設定

![Picture13](images/remotework048.jpg?raw=true)

それでは、順に設定していきます。

#### 6.2.1.  送信先 SRT 接続

「⚙Settings」→「Connection」→「New connection」で以下の接続を追加してください。

![Picture.14](images/remotework044.jpg?raw=true)

| 項目 | 設定値 |
| --- | ----- |
| Name | この接続の名前。ここでは例として「vMix SRT 10001」とします |
| URL | 「サーバー」に以下のフォーマットで送信先 URL を記入<br />srt://`アドレス`:`port番号`<br />例: `srt://192.168.0.10:10001` |
| Mode | Audio + Video |
| SRT sender mode | Caller |
| latency (msec) | 240 ※単位ミリ秒 |
| passphrase | 10文字以上79文字以下のパスワード |
| pbkeylen | 16 |
| streamid | 空欄のまま |
| Retransmission algorithm | Default のまま |
| maxbw (bytes/sec) | 空欄のまま |

※URLを入力すると Mode 以降の設定項目が出現します。

「SAVE」で保存してください。

その後、「設定した接続名（vMix SRT 10001）」にチェックが入っているかを確認してください。

![Picture.15](images/remotework045.jpg?raw=true)

#### 6.2.2. トークバック受信元　SRT 接続

「⚙Settings」→「Talkback」→「New connection」で以下の接続を追加してください。

![Picture.16](images/remotework046.jpg?raw=true)

| 項目 | 設定値 |
| --- | ----- |
| Name | この接続の名前。ここでは例として「vMix SRT 10003」とします |
| URL | 「サーバー」に以下のフォーマットで送信先 URL を記入<br />srt://`アドレス`:`port番号`<br />例: `srt://192.168.0.10:10003` |
| Buffering (msec) | 500 ※単位ミリ秒 |
| SRT receiver mode | Caller |
| Latency (msec) | 240 ※単位ミリ秒 |
| passphrase | 10文字以上79文字以下のパスワード |
| pbkeylen | 16 |
| streamid | 空欄のまま |
| maxbw (bytes/sec) | 空欄のまま |

※URLを入力すると Mode 以降の設定項目が出現します。

「SAVE」で保存してください。

その後、「設定した接続名（vMix SRT 10003）」にチェックが入っているかを確認してください。

![Picture.17](images/remotework047.jpg?raw=true)

#### 6.2.3. Video の設定

「⚙Settings」→「Video」で以下の様に設定してください。

| 項目 | 設定値 |
| --- | ----- |
| Start app with | Rear camera がメインカメラで、Front camera がサブカメラ（セルフィー用）です。 |
| Video Size | 1920x1080 |
| FPS | 8-30 variable rate |
| Background streaming | チェック入れる |
| Focus mode | Continuous auto focus |
| White balance | Auto |
| Anti-flicker | Auto ※お好みに合わせて変更 |
| Exposure value | 0 ※お好みに合わせて調整 |
| Noise reduction | System default ※お好みに合わせて変更 |
| Video stabilization | 手振れ補正設定ですので、お使いの機種とお好みに合わせて変更してください。<br />EISが電子式で、OISが光学式です。|
| Vertical stream | チェック無し |
| Live rotation | チェック有りのまま |
| Bitrate | 1000 kbps ※h.264ならもう少し上げる（例：1500 kbps） |
| Keyframe frequency | 1sec |
| Format | HEVC ※推奨 |
| HEVC profile | System default |
| Adaptive bitrate streaming | 当方でテストした限りではうまく機能しない事が有るので OFF のまま推奨 |

Format に HEVC(h.265)を選ぶと、同等画質の場合に h.264 よりも Bitrate を抑えることが出来るため送信品質が良くなります。
Bitrate の設定は、お使いのモバイルネットワーク環境に応じて調整してください。

Adaptive bitrate streaming は回線状況に応じてビットレートを変化してくれると言う非常に有用な機能なのですが、
当方にてテストを実施した所、一度最低ビットレートまで落ちるとそのままずっと通常ビットレートに戻らず、
配信を再起動するまで最低ビットレートのままという不具合があるようです。従って本レシピでは OFF を推奨とします。

#### 6.2.4. Audio の設定

「⚙Settings」→「Audio」で以下の様に設定してください。

| 項目 | 設定値 |
| --- | ----- |
| Audio source | スマートフォン内蔵のマイクやマイク入力端子を使う場合は「Camcorder」、<br />USB接続の音源を使う場合は「External mic(if present)」を選択 |
| Channel count | Stereo |
| Bitrate | 128 kbps |
| Sample rate | 48000 |
| Audio-only capture | チェック無し |
| Prefer bluetooth MIC | チェック無し |

#### 6.2.5. その他の設定

「⚙Settings」→「Recording」では、録画の設定が出来ます。
スマートフォンに録画を残したい場合は、「Record stream」にチェックを入れてください。
こちらで、配信中の絵音が録画として残ります（録画品質は Video で設定した物と同じになります）

![Picture.18](images/remotework049.jpg?raw=true)

「⚙Settings」→「Advanced options」で、「Show audio level meter」にチェックを入れてください。
Audio のレベルメーターがプレビュー画面に表示されます。

![Picture.19](images/remotework050.jpg?raw=true)

### 6.3. 疎通確認

セットアップと設定が完了したら、早速動作確認をしましょう。
まず、Talkback は一度設定すると自動的に接続が行われて常に受信状態となります。
スタジオで喋った音声が、出演者のスマートフォンに届いているかを確認してください。
Larix Broadcaster 上では「Talkback ONLINE」と表示されているはずです。

また、出演者が喋ると、Larix Broadcaster 上のレベルメーターが振れるはずですから、きちんと Audio が撮れているかを確認してください。

![Picture.20](images/remotework053.jpg?raw=true)

次に、スタジオへ絵音を送信するために、「赤い●」をタップしてください。「赤い■」に変わって送出が開始されます。
また、Recording を ON にしている場合は録画も開始されます。

1.2Mbps, 1.2MB の様な表示が画面下部に出ていれば無事送出が行われています。
vMix に接続できない場合はエラーが表示されますので SRT 接続の設定を確認し、その後モバイルネットワークの状態も確認してください。

![Picture.21](images/remotework054.jpg?raw=true)

Background Streaming が ON になっている場合は Larix Broadcaster 以外のアプリを立ち上げてもバックグラウンドで送信し続けます。
例えば、Web ブラウザでネットを見たり、YouTube で視聴者コメントやオンエアを確認したり、Discord でチャットを見たり、
Twitter でツイートしたりできます。
注意点としては、カメラアプリで撮影や Line、Discord、電話等で通話をしようとすると、
Larix Broadcaster とアプリがカメラやマイクデバイスを奪い合う格好になるため、本番中は行わない様にしてください。
**送信が停止するだけでなく、最悪スマートフォンがフリーズします。**

写真の撮影は、Larix Broadcaster のスナップショット機能を使ってください。

![Picture.22](images/remotework055.jpg?raw=true)

最後に、スタジオ側で、vMixに出演者のスマートフォンから絵音が正しく送られているかを確認してください。

![Picture.23](images/remotework056.jpg?raw=true)

送信されていても映像が乱れる場合は、現地とスタジオ間の通信状況が良くないので、以下の対策を講じてください。

1. 映像ビットレートを下げる（トレードオフとして画質が悪くなります）
2. latency の値を増やす（トレードオフとして遅延が増えます）<br />
   latency を増やす場合は、全出演者側の Larix Broadcaster とスタジオ側の vMix とで同一の値に設定してください。

通信の状況は vMix ウインドウ右下の「📊Statistics」→「SRT」で確認できます。
以下の RTT が ping 値になりますので、これをもとに Latency の値を見直してください。Packet Loss(%) が　1 % を超える場合は、
Latency 値を更に増やす必要があります。

Latency 値は RTT（Ping）値の倍数で設定してください。

![Picture.28](images/remotework024.jpg?raw=true)

![Picture.29](images/remotework023.jpg?raw=true)

また、モバイル配信はクオリティが現地の電波状況に依存するので、「アンテナが何本立っているか」にも注意してください。
都市部は地下にでも入らない限りほとんど問題ないと思いますが、山間部は安定して配信できない場合も多いです。
