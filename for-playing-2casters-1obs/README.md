# プレイング配信システム（出演者2名分）レシピ【改良版】

## 0. 前提

> 本レシピは [プレイング配信システム（出演者2名分）レシピ](../for-playing-2casters) の改良版です。
> 出演者が起動する OBS Studio インスタンスが 2 つから 1 つに減りました。

本レシピでは、プレイング配信を行う上で、リモートから全出演者が参加する場合の配信システムを構築したいと思います。
今回も SRT という聞きなれないプロトコルを駆使することで、低遅延かつ高品質で信頼性の高いシステムを目指します。

尚、DISCORD、OBS Studio、vMix、その他配信に関する基本的な知識、PCの知識があることを前提とします。

SRT に関する説明は、[「ビューイング配信システム」の記事](https://blog.opensphere.co.jp/posts/remotework001) を読んでいる前提として割愛します。

## 1. 要件定義

1. 出演者はゲームに参加し実況プレーするプレイング配信。
2. 出演者が 2 名。それぞれリモートから配信に参加し、お互いにボイスコミュニケーションが可能とする。
3. 配信オペレーターは 1 名、出演者とは別の場所（スタジオ）で配信を実施する。
4. 配信オペレーターからトークバックで出演者に指示を出せる。トークバックは配信には乗せないこと。
5. 出演者 2 名から、それぞれゲーム映像（＋ゲーム音声）と Webcam 映像（＋マイク音声）を受け取って、スタジオで合成して配信する。
6. 出演者 2 名には、Output の絵を返す。
7. 出演者 2 名は自分の配信機材を使用する。運営から特別な機材を用意しない。
    
## 2. 用意するもの

### 2.1. スタジオ側

* [DISCORD（サーバーも）](https://discord.com/)
* [vMix（HD エディション以上）](https://www.vmix.com/)
* ポートフォーワーディング可能なポート番号 4 つ
* パスワード（10 文字以上 79 文字以下）
* アップロード・ダウンロード共に　100 Mbps 以上出る光インターネット回線

### 2.2. 出演者側

* [DISCORD](https://discord.com/)
* [OBS Studio](https://obsproject.com/) ※v30.1 以上
* [Branch Output プラグイン](https://github.com/OPENSPHERE-Inc/branch-output)
* Webcam
* その他、出演者がいつも使ってる配信機材
* アップロード・ダウンロード共に　50 Mbps 以上出る光インターネット回線

## 3. システム図

![Picture.1](images/remotework001.jpg?raw=true)

※出演者は DISCORD の画面共有で配信 Output をモニター出来ますが、あくまでも絵の確認用で、画質や低遅延は追及しません。
また、映像のみで Audio はモニターできません。

※ゲーム音とマイク音をパラ（別々）で送るので、スタジオの vMix 側で音量バランスの調整が出来ます。

## 4. スタジオ側の仕込み

### 4.1. DISCORD の設定

お互いに音声通話しながら仕込みを行うでしょうから、まず DISCORD から準備してください。

[こちらから DISCORD をダウンロード](https://discord.com/)してインストールし、アカウントを作成してログインしてください。
また、専用のサーバーを作成して接続し、招待リンクを生成して出演者側に知らせてください（出演者にサーバーへ接続してもらう）
最後に、音声通話できる様、音声デバイスを設定してボイスチャンネルに参加してください。

尚、配信用の出演者音声は、SRT で送られてきますので、DISCORD の音声は vMix に取り込む必要はありません。

今回のレシピでは、DISCORD の画面共有で 出演者に配信 Output を返します。
こちらについては、vMix の設定の最後で説明します。

### 4.2. ポートフォーワーディングの設定

出演者からは合計4セットの絵音を受け取りますから、ポート番号を4つ決めてください。
ここでは `10001`, `10002`, `10003`, `10004` とします。

- 出演者A に `10001`（Webcam用）、`10002`（Game用）
- 出演者B に `10003`（Webcam用）、`10004`（Game用）
 
上記をそれぞれ割り当てるとし、出演者に渡してください。<br />

ポート番号を決めたら、SRT を受信するPCに対して UDP でポートフォーワーディングを設定してください。
ポートフォーワーディング設定の仕方は、お使いのブロードバンドルーターのマニュアルを参照するか、ネットワーク担当者に問い合わせてください。

### 4.3. vMix の設定

SRT を受信する Input は4つ必要です。
上記で設定した 4 つのポート番号について、それぞれ「Stream / SRT」で Input を作成してください。
「Add Input」→「Stream / SRT」を開いてください

| 項目                   | 設定値                                          |
|----------------------|----------------------------------------------|
| Stream Type          | SRT (Listener)                               |
| Port                 | 10001                                        |
| Latency (ms)         | 120 ※ここだけ単位がミリ秒なので注意                         |
| Decoder Delay (ms)   | 0                                            |
| Passphrase           | 10文字以上79文字以下のパスワード。出演者側の OBS Studio に同じものを設定 |
| Key Length           | 変更不要                                         |
| Stream ID            | 空欄のまま                                        |
| Use Hardware Decoder | チェック入れる                                      |

![Picture.2](images/remotework003.jpg?raw=true)

同じ手順で、もう3つ分（10002、10003, 10004）ポート番号を変えて作成してください。

Output を DISCORD から取り込むため、
「Settings」→「External Output」→「External」→「vMix Video / Streaming」にチェックを入れてください。

![Picture.3](images/remotework015.jpg?raw=true)

また、vMix ウインドウの下部にある「External」ボタンを押して、External 出力を有効にしてください。

DISCORD 側では、ビデオ通話を開始し、カメラデバイスとして「vMix Video」を選択すれば、映像を取り込むことが出来ます。
尚、出演者には映像のみ返しますから、Audio は取り込む必要がありません。

![Picture.4](images/remotework016.jpg?raw=true)

> DISCORD に表示された映像が左右反転しますが、これ仕様です。
> 実際は正しい向きの映像が共有されています。
> 本来は Webcam を映す物なので、ユーザビリティの都合で、鏡の様に自分の姿が左右反転します。

## 5. 出演者側の仕込み

### 5.1. DISCORD の設定

お互いに音声通話しながら仕込みを行うでしょうから、まず DISCORD から準備してください。

[こちらから DISCORD をダウンロード](https://discord.com/)してインストールし、アカウントを作成してログインしてください。
本レシピでは、DISCORD は常に OBS Studio と同じ PC にインストールすることを推奨します (\*)。理由と設定方法は後述します。

次に、スタジオ側から送られてきた招待リンクを開いてサーバーに接続し、ボイスチャンネルに参加してください。
また、音声通話できるように音声デバイスを設定しましょう。

DISCORD は出演者間のボイスコミュニケーションと、スタジオからのトークバックにのみ使用します。
原則として DISCORD の音声を配信にミックスしたりはしません。理由としては音質の問題です。

出演者の音声は前述の SRT で、Webcam 映像と共にスタジオまで送信します。
このことで、品質を確保し、映像と音声の同期（リップシンク）を取る手間を省きます。

最後に、ホストが行っている画面共有を視聴し、疎通を確認してください。

---
(\*) 本レシピはあくまでも一例なので、「DISCORD 音を配信に乗せない」という要件を満たせれば、アレンジしても構いません。

### 5.2. OBS Studio の設定

以前のレシピと違い、OBS Studio は 1 つのインスタンス起動で事足ります。
プラグインを使用して、ゲーム映像と Webcam をパラで送出します。

OBS Studio に[Branch Output プラグイン](https://github.com/OPENSPHERE-Inc/branch-output) をインストールしてください。

[Branch Output プラグインの使い方はこちら](https://blog.opensphere.co.jp/posts/branchoutput001)

#### 5.2.1. Webcam 出力の設定

今回も顔出し配信を想定していますから、Webcam の映像とマイク音声をスタジオに送信するために、
OBS Studio に Webcam とマイク追加してください。

- Webcam は、ソースに「映像キャプチャデバイス」を追加
- マイクは、「設定」→「音声」→「グローバル音声デバイス」→「マイク音声」で設定

![Picture.5](./images/remotework007.jpg?raw=true)

次に Branch Output で Webcam を送出する設定です。SRT というプロトコルを使用します。
使用するポートは、前述の「ポートフォーワーディングの設定」で決めたものになりますから、下記の port番号を適時置換してください。

ここでは、Webcam: `10001`, Game: `10002` とします。

1. Webcam ソースを選択して「フィルタ」をクリック
2. 「エフェクトフィルタ」の「プラス」アイコンをクリックして「Branch Output」を選択。適当な名前を決めて入力し「OK」をクリック。
3. 「サーバー」に以下のフォーマットで送信先 URL を記入<br />
   srt://`アドレス`:`port番号`?mode=caller&passphrase=`パスワード`&latency=`レイテンシ(μsec)`&pbkeylen=`暗号化キーの長さ`<br />
   例: `srt://192.168.0.10:10001?mode=caller&passphrase=enjoysrt&latency=120000&pbkeylen=16`<br />
4. 「ストリームキー」は今回使用しないので空欄のままで OK です。
   
   ![Picture.6](images/remotework008.jpg?raw=true)
    
5. 「カスタム音声ソース」にチェックを入れ、ソースに `マイク` を選択してください。
 
   ![Picture.7](images/remotework008-1.jpg?raw=true)

6. 「音声エンコーダ」で `FFmpeg AAC` を選択し、ビットレートに妥当なビットレート（例:`160` Kbps）を選択してください。

   ![Picture.8](images/remotework008-2.jpg?raw=true)

7. 「映像エンコーダ」を以下の表を参考にして設定してください。

   | 項目       | 設定値                       |
   |----------|---------------------------|
   | 映像エンコーダ  | 「NVIDIA NVENC H.264」推奨    |
   | レート制御    | CBR                       |
   | ビットレート   | 妥当なビットレート(例: `6000 Kbps`) |
   | キーフレーム間隔 | `0 s`                     |
   | チューニング   | `超低遅延`                    |
   | マルチパスモード | `1パス`                     |

   ※選択したエンコーダーによって項目名が変わる可能性があります。

   ![Picture.9](images/remotework009.jpg?raw=true)

8. 「適用」をクリック

以上で vMix に Webcam 映像＋マイク音声の SRT 送出が開始されます。

> Branch Output はフィルタが有効である限り、送出が継続します。ネットワークが切断されても再接続を試行します。
> 
> 送出を一時的に止めたい場合はフィルタの「目」アイコンをクリックし、無効化してください。

#### 5.2.2. ゲーム映像の設定

次に、OBS にゲーム映像を追加してください。

ゲーム映像に使用するソースは以下の2パターンが考えられます。

- OBS Studio と同じ PC で起動する PC ゲーム
  **→「ゲームキャプチャ」ソースを使用**
- OBS Studio とは別の PC で起動する PC ゲーム、またはコンソールゲーム（他、モバイルゲームも同様）
  **→「映像キャプチャデバイス」ソースを使用**

![Picture.10](images/remotework021.jpg?raw=true)

ここで、DISCORD 音はゲーム音と共に出演者が聴けなくてはなりませんので、ひと工夫必要になります。
何も考えずに出演者が聴いているゲーム音と DISCORD 音をデスクトップ音声で取り込もうとすると、
当然、ゲーム音に DISCORD 音が乗った状態で配信されてしまいます。
これを回避するため、環境に応じて ケースA あるいは ケースB どちらかの対策を講じてください。

**どちらのケースでも、ゲーム音 ＋ Discord 音は OBS Studio の PC から聴く形となります。**

##### ケースA: 1 PC 配信

![Picture.11](images/remotework029.jpg?raw=true)

ここでは、ゲームと OBS Studio が同じ PC という構成を 1 PC 配信と呼称します。
1 PC 配信では、ゲームキャプチャでゲーム音声のみキャプチャする場合、構成を単純にできます。

**《サウンドデバイスX》** は Windows のサウンド設定で「出力デバイス」に指定されており、
DISCORD 音が再生され、ヘッドセット（スピーカー）が接続されています。

1. 「ソース」ドックの「プラス」アイコンをクリックし、「ゲームキャプチャ」を選択。適当にソースに名前を付けて「OK」をクリックしてください。
2. 「モード」で `フルスクリーンアプリケーションをキャプチャ` を選択
3. 「音声をキャプチャ（ベータ版）」にチェックを入れる
4. 「OK」をクリック（ソースが作成されます）

   ![Picture.12](images/remotework029-1.jpg?raw=true)

5. OBS Studio の「設定」→「音声」→「グローバル音声デバイス」→「デスクトップ音声」を「無効」に設定
   つまりデスクトップ音声の取り込みを行わない様にします。

   ![Picture.12](images/remotework029-3.jpg?raw=true)

6. 音声ミキサーの「ギア」アイコンをクリックし「オーディオ詳細プロパティ」を開いて、音声モニタリングを全て「モニターオフ」にしてください。

   ゲーム音声＋DISCORD音声の出力は、普段ゲームをプレイしている状態から変える必要はありません。

7. 続けて配信の設定をします。「ソース」ドッグで「ゲームキャプチャ」ソースを選択し「フィルタ」をクリック
8. 「エフェクトフィルタ」の「プラス」アイコンをクリックして「Branch Output」を選択。適当な名前を決めて入力し「OK」をクリック。
9. Webcam の時と同様にサーバーに送信先 URL を入力してください。
   ポートは Webcam 用とは別のポート（ここでは Game 用 `10002` とします）を使用します。
10. 「カスタム音声ソース」からチェックを外してください。この設定により「ゲームキャプチャ」ソースの音声が使用されます。
11. 以降は、Webcam の時と同様に音声エンコーダーと映像エンコーダーを設定してください。
12. 「適用」をクリック

以上で vMix にゲーム映像＋ゲーム音声の SRT 送出が開始されます。

> <details>
> 
> <summary> ゲームキャプチャの「音声をキャプチャ」が使えなかった場合のバックアッププラン</summary>
> 
> ゲームキャプチャが使えなかった場合は、デスクトップ音声としてゲーム音声を取り込みます。
> その場合は 2 つのサウンドデバイスを使用する従来の方法になります。
>
> ![Picture.13](images/remotework029-2.jpg?raw=true)
> 
> - **《サウンドデバイス1》**
>   ゲーム音を再生するデバイスで Windows のサウンド設定で「出力デバイス」に指定
> - **《サウンドデバイス2》**
>   DISCORD 音を再生するデバイスでヘッドセット（スピーカー）が接続されているデバイス
>
> 設定手順は下記の通りです。
>
> 1. OBS Studio の「設定」→「音声」→「グローバル音声デバイス」→「デスクトップ音声」に《サウンドデバイス1》を設定
> 2. 「詳細設定」→「モニタリングデバイス」に《サウンドデバイス2》を設定
>
>    ![Picture.13](images/remotework025.jpg?raw=true)
>
> 3. 「音声ミキサー」→「ギア」アイコン→「オーディオの詳細プロパティ」→「デスクトップ音声」→「音声モニタリング」で「モニターと出力」を選択
>
>    ![Picture.14](images/remotework026.jpg?raw=true)
>
> 4. タスクバーの「スピーカー」アイコンを右クリック→「サウンドの設定を開く」→「出力サウンドを選択してください」に《サウンドデバイス1》を選択
>
>    ![Picture.15](images/remotework027.jpg?raw=true)
>
> 5. DISCORD の「⚙ユーザー設定」→「音声・ビデオ」→「出力デバイス」を《サウンドデバイス2》に設定
>
>    ![Picture.16](images/remotework028.jpg?raw=true)
>
> これで《サウンドデバイス2》に接続したヘッドホン（スピーカー）からゲーム音 + DISCORD 音を聞けます。
> 
> Branch Output のカスタム音声ソースにはチェックを入れて、音声ソースに「デスクトップ音声」を選択してください。
> 
> </details>

##### ケースB: 2 PC 配信

![Picture.17](images/remotework030.jpg?raw=true)

ここでは、ゲームと OBS Studio が別々の PC （あるいはゲームコンソール）という構成を、2 PC 配信と呼称します。
2 PC 配信では、1 つのサウンドデバイスだけ使用します。

**《サウンドデバイスX》** は Windows のサウンド設定で「出力デバイス」に指定されており、
DISCORD 音が再生され、ヘッドセット（スピーカー）が接続されています。

設定手順は下記の通りです。

1. 「詳細設定」→「モニタリングデバイス」に《サウンドデバイスX》を設定

   ![Picture.18](images/remotework031.jpg?raw=true)

2. 「音声ミキサー」→「ギア」アイコン→「オーディオ詳細プロパティ」→「映像キャプチャデバイス」→「音声モニタリング」で「モニターと出力」を選択

   ![Picture.19](images/remotework032.jpg?raw=true)

3. タスクバーの「スピーカー」アイコンを右クリック→「サウンドの設定を開く」→「出力サウンドを選択してください」に《サウンドデバイスX》を選択

   ![Picture.20](images/remotework033.jpg?raw=true)

4. DISCORD の「⚙ユーザー設定」→「音声・ビデオ」→「出力デバイス」を《サウンドデバイスX》に設定

   ![Picture.21](images/remotework034.jpg?raw=true)

   これで《サウンドデバイスX》に接続したヘッドホン（スピーカー）からゲーム音 + DISCORD 音を聞けます。

5. 続けて配信の設定をします。「ソース」ドッグで「ゲームキャプチャ」ソースを選択し「フィルタ」をクリック
6. 「エフェクトフィルタ」の「プラス」アイコンをクリックして「Branch Output」を選択。適当な名前を決めて入力し「OK」をクリック。
7. Webcam の時と同様にサーバーに送信先 URL を入力してください。ポートは Game 用を使用します。
8. 「カスタム音声ソース」からチェックを外してください。この設定により「映像キャプチャデバイス」ソースの音声が使用されます。
9. 以降は、Webcam の時と同様に音声エンコーダーと映像エンコーダーを設定してください。 
10. 「適用」をクリック

> #### 出演者がアナログミキサーを使用していた場合は？
>
> 出演者が本格的なミキシングコンソール（アナログミキサー）を使って配信環境を構築している場合は、少し話がややこしくなります。
>
> 1. ゲーム音とマイク音はパラで OBS Studio PC に入力する事（可能なら）
> 2. ゲーム音に DISCORD 音を混ぜない事（必須）
> 3. 出演者がゲーム音と DISCORD 音を聴ける事（必須）
> 4. マイク音を DISCORD に入力する事（必須）
>
> 上記の要件を満たすようにセッティングが必要です。
> 最悪、ゲーム音とマイク音が混ざってしまっても（1 の要件が満たせなくても）致命的な問題ではないですが、音量バランスの調整が出演者側でしか行えません。

### 5.3. 疎通確認

全ての設定が済んだら、Webcam 映像（＋マイク音声）、ゲーム映像（＋ゲーム音声）がスタジオ側の vMix に送信されていることを確認してください。

![Picture.27](images/remotework017.jpg?raw=true)

ゲーム画面は特に画質が求められるので、満足な品質が得られているかも確認してください。
必要に応じて（ネットワーク帯域が許すなら）映像のビットレートを上げましょう。

絵音が来ない場合は OBS Studio かスタジオ側の vMix のどちらかの設定がおかしい可能性があります。

また、送信されていても映像が乱れる場合は、出演者宅とスタジオ間の通信状況が良くないので、以下の対策を講じてください。

1. 映像ビットレートを下げる（トレードオフとして画質が悪くなります）
2. latency の値を増やす（トレードオフとして遅延が増えます）<br />
   latency を増やす場合は、全出演者側の OBS Studio とスタジオ側の vMix とで同一の値に設定してください。

通信の状況は vMix ウインドウ右下の「📊Statistics」→「SRT」で確認できます。
以下の RTT が ping 値になりますので、これをもとに Latency の値を見直してください。Packet Loss(%) が　1 % を超える場合は、Latency 値を更に増やす必要があります。

Latency 値は RTT（Ping）値の倍数で設定してください。

![Picture.28](images/remotework024.jpg?raw=true)

![Picture.29](images/remotework023.jpg?raw=true)

### 5.4. 注意点

SRT の latency は全ての OBS Studio で同一の値を使ってください。
また、vMix 側でも同一の時間に設定してください。

つまり、1か所の OBS Studio で latency を増やした場合は、他の OBS Studio も同様に増やさなければならず、vMix 側も同様の時間に設定します。

そうすることにより、絵音のタイミングが大体揃います。

