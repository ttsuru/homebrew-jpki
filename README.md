# homebrew-jpki

[English](README.en.md)

[公的個人認証サービス 利用者クライアントソフト（Mac 版）](https://www.jpki.go.jp/download/mac.html) を
[Homebrew](https://brew.sh/) で導入・更新・削除するためのサードパーティ tap です。

マイナンバーカードを e-Tax などの電子申請で使うには、地方公共団体情報システム機構（J-LIS）が配布する
利用者クライアントソフトが必要です。公式サイトからは `.dmg` を手で落として `.pkg` を実行する
形でしか配布されていないため、この tap がその手順を Cask として定義し、以下をコマンド一つで
できるようにします。

- 公式サイトの正規 URL からインストーラを取得し、SHA-256 を検証してからインストールする
- `brew upgrade` で新バージョンへ追従する（公式サイトを毎日 livecheck して更新 PR を自動作成）
- `brew uninstall` で公式アンインストーラと同等の削除を行い、`--zap` で設定ファイルも含めて完全に消す

> **注意** この tap は利用者クライアントソフト本体を再配布していません。Cask は公式配布 URL を
> 指しているだけで、ソフトウェア本体の利用条件は J-LIS の
> [ご利用条件](https://www.jpki.go.jp/download/mac.html) に従います。

## 動作要件

| 項目 | 内容 |
| --- | --- |
| macOS | 13 Ventura 以降（アプリ本体の `LSMinimumSystemVersion` が 13.5）。公式の動作検証は直近 2 世代のみ |
| CPU | Intel、または Apple Silicon + Rosetta 2（`JPKI.app` と `JPKIUtility.app` が x86_64 専用のため） |
| Homebrew | 6.0 以降（サードパーティ tap の trust 機構を前提にしています） |
| その他 | IC カードリーダライタ、マイナンバーカード |

Rosetta 2 が未導入の場合は次で入ります。

```sh
softwareupdate --install-rosetta --agree-to-license
```

## インストール

```sh
brew install --cask ttsuru/jpki/jpki
```

フルネームで指定すると、Homebrew はこの Cask だけを信頼して tap を自動追加します。
tap 全体を信頼して短い名前で扱いたい場合は次のようにします。

```sh
brew tap ttsuru/jpki
brew trust --tap ttsuru/jpki
brew install --cask jpki
```

インストーラは署名・公証済みの `.pkg` で、`/Applications`、`/Library`、`/usr/local/lib` に
書き込むため管理者パスワードを求められます。インストール完了時に公式インストーラが Finder と
「更新通知設定」アプリを自動で開きますが、これは J-LIS のインストーラ自身の挙動です。

`Brewfile` で管理する場合:

```ruby
tap "ttsuru/jpki"
cask "jpki"
```

### すでに公式 dmg から手動インストール済みの場合

そのまま `brew install --cask ttsuru/jpki/jpki` を実行して構いません。パッケージ ID
（`jp.go.jpki`）が同一なので、Apple のインストーラが上書きアップグレードとして扱い、
以後は Homebrew から更新・削除できるようになります。

## インストール後の設定

Cask の caveats にも表示されますが、ブラウザ側の設定が別途必要です。

- **Safari**: 「Safari > 設定 > 機能拡張」で **JPKI** を有効化する
- **Chrome**: Chrome ウェブストアから **JPKI利用者ソフト** 拡張機能を追加する
- **Java は通常不要です。** 公式の案内どおり、Ver 2.4 以降はブラウザ利用に JRE を必要としません。
  「Java 実行環境への登録」（`JPKIRegistBCA.app`）と `JPKIProxySetting.app` だけが Java を使い、
  これらは `/Library/Internet Plug-Ins/JavaAppletPlugin.plugin` にある **Oracle 製 JRE 8**
  （[java.com](https://www.java.com/ja/)）をハードコードで探します。Homebrew の `openjdk` や
  `temurin` では認識されないため、この tap では Java を依存関係にしていません。
  利用する電子申請サービスが Java インタフェースを要求する場合だけ、公式手順
  [JRE の導入方法](https://www.jpki.go.jp/e-apply/jre.html) に従って導入してください。
  ランチャーの解析結果は [docs/maintenance.md](docs/maintenance.md#java-連携アプリjpkiregistbcaapp--jpkiproxysettingappの実態) を参照してください。

公式の手順書: [利用者クライアントソフトの利用方法（Mac）](https://www.jpki.go.jp/download/howto_mac/index.html)

## 更新

```sh
brew update
brew upgrade --cask jpki
```

この tap は毎日 公式サイトを [livecheck](.github/workflows/autobump.yml) し、新バージョンが
公開されると自動で更新 PR を作成します。手元で確認したい場合:

```sh
brew livecheck --cask ttsuru/jpki/jpki
```

## アンインストール

```sh
brew uninstall --cask jpki          # 公式アンインストーラ相当
brew uninstall --cask --zap jpki    # 設定ファイル・コンテナも含めて完全削除
```

`uninstall` は次を行います（公式の `JPKIUninstall.command` と同等）。

1. 更新通知の LaunchAgent `jp.go.jpki.JPKIUpdateReminder` を停止
2. 起動中の JPKI 関連アプリを終了
3. パッケージレシート `jp.go.jpki` に記録された全ファイルを削除
   （`/Applications/JPKI.app`、`/Applications/Utilities/JPKI`、`/usr/local/lib/JPKI*`、
   `/Library/Java/Extensions/*JPKI*`、Chrome の NativeMessagingHosts など）

`--zap` ではさらに次を削除します。

- `~/Library/Containers/jp.go.jpki*`、`~/Library/Group Containers/LQF3UNS9HK.jp.go.jpki`
- `/etc/e-gov_app/load_path/default.dat*`（他の電子申請ソフトが PKCS#11 モジュールを探すための
  ロードパスファイル。公式アンインストーラも残す設計のため、通常の `uninstall` では消しません）

## `brew doctor` の警告について

インストール後、`brew doctor` が次の警告を出します。

```text
Warning: Unbrewed dylibs were found in /usr/local/lib.
Unexpected dylibs:
  /usr/local/lib/JPKIPKCS11.dylib
  /usr/local/lib/JPKIPKCS11Auth.dylib
  /usr/local/lib/JPKIPKCS11Sign.dylib
  /usr/local/lib/JPKIServiceAPI.dylib
```

これは無害で、Cask 側では回避できません。PKCS#11 モジュールの配置先は J-LIS の
API 仕様で `/usr/local/lib` に固定されており、他のアプリがそのパスを前提に読み込むためです。
根本対処として Homebrew 本体の許可リストへ追加するパッチを
[patches/](patches/) に用意しています。詳細は [docs/brew-doctor.md](docs/brew-doctor.md) を参照してください。

## 中身を確認したい方へ

Cask が何をするかは [Casks/jpki.rb](Casks/jpki.rb) を読めば全てわかります。
インストーラの構成（ペイロード、pre/post install スクリプト、署名）と、それを踏まえた
Cask の設計判断は [docs/maintenance.md](docs/maintenance.md) にまとめています。

## 開発・貢献

バージョン更新や不具合報告は歓迎します。手順は [CONTRIBUTING.md](CONTRIBUTING.md) を参照してください。
脆弱性の報告は [SECURITY.md](SECURITY.md) に従ってください。

## ライセンス

この tap（Cask 定義・ドキュメント・CI）は [MIT License](LICENSE) です。
利用者クライアントソフト本体の著作権は地方公共団体情報システム機構にあり、この tap には含まれていません。
