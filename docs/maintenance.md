# メンテナンスガイド

この tap の Cask は、公式インストーラ `JPKIMac_MM-mm_XX-YY.dmg` の中身を解析して書かれています。
新バージョンが出たときに「何が変わると Cask を直す必要があるか」を判断できるよう、
解析結果と設計判断をここに残します。

## インストーラの構成（Ver 3.9 時点）

| 項目 | 値 |
| --- | --- |
| ダウンロード URL | `https://www.jpki.go.jp/client/download/101/JPKIMac_03-09_01-01.dmg` |
| dmg の中身 | `JPKIInstall.pkg` のみ（distribution 形式、内部コンポーネント `JPKIInst.pkg`） |
| パッケージ ID | `jp.go.jpki`（`pkgutil --pkgs` で確認できる） |
| 署名 | Developer ID Installer: Japan Agency for Local Authority Information Systems (`LQF3UNS9HK`)、公証済み |
| 最小 macOS | `JPKI.app` の `LSMinimumSystemVersion` = 13.5 |
| アーキテクチャ | `JPKI.app`、`JPKIUtility.app`、Safari 機能拡張は x86_64 のみ。それ以外の app と dylib は universal |

### 配置されるファイル

```text
/Applications/JPKI.app                                  # ブラウザ連携（Native Messaging ホスト + Safari 機能拡張）
/Applications/Utilities/JPKI.localized/                 # ユーティリティ群
  JPKIUtility.app, JPKIChangePassword.app, JPKIChangeAllPassword.app,
  JPKIUpdateReminderSetting.app, JPKIProxySetting.app (Java: Oracle JRE 8 固定),
  JPKIRegistBCA.app (Java: Oracle JRE 8 固定), JPKIUninstall.app
/usr/local/lib/JPKIPKCS11.dylib                         # PKCS#11 モジュール（署名用・認証用・統合）
/usr/local/lib/JPKIPKCS11Auth.dylib
/usr/local/lib/JPKIPKCS11Sign.dylib
/usr/local/lib/JPKIServiceAPI.dylib
/usr/local/lib/JPKI/                                    # JNI ライブラリ、jar、更新通知アプリ、JPKIutil.ini
/Library/Java/Extensions/*JPKI*.{jar,jnilib}            # Java 連携
/Library/LaunchAgents/jp.go.jpki.JPKIUpdateReminder.plist
/Library/Google/Chrome/NativeMessagingHosts/jp.go.jpki.json
```

### インストールスクリプト

- `preinstall`
  - `/private/etc/e-gov_app/load_path/default.dat` を作成（既存があれば `default.dat1..17`、`default.dat_bk` へローテーション）
  - すべての `/Users/*` に `Library/Group Containers/LQF3UNS9HK.jp.go.jpki` を作成
- `postinstall`
  - `osascript` で Finder の `JPKI.localized` フォルダと `JPKIUpdateReminderSetting.app` を開く（GUI が無い環境でも `exit 0`）
- `preflight` / `preupgrade` / `postupgrade`
  - 旧形式（bundle package）用のスクリプトで、flat package では実行されない。`preflight` は Oracle JRE を要求する古いコードが残っているが無視される

### Java 連携アプリ（`JPKIRegistBCA.app` / `JPKIProxySetting.app`）の実態

両アプリの `Contents/MacOS/JavaAppLauncher` は Oracle 純正の汎用ランチャーではなく、J-LIS 製の
約 170KB のプログラムです。インポートしている関数は `fopen` / `fclose` / `system` /
`CFUserNotificationCreate` だけで、`main` は次の 3 ステップしかありません（arm64 の逆アセンブルで確認）。

1. `fopen("/Library/Internet Plug-Ins/JavaAppletPlugin.plugin/Contents/Home/bin/java", "r")` で
   **Oracle JRE の実体ファイルの存在を確認**する
2. 開けなければ `CFUserNotification` でエラーダイアログを出し、`-1` で終了する
3. 開ければ `system()` で次を実行する（`JPKIRegistBCA` は `-Djava.library.path=...:/Library/Java/Extensions` 付き）

   ```sh
   export JAVA_HOME=/Library/Internet\ Plug-ins/JavaAppletPlugin.plugin/Contents/Home ; java -jar /Applications/Utilities/JPKI.localized/JPKIProxySetting.app/Contents/Java/JPKIProxySetting.jar
   ```

`/usr/libexec/java_home` や `/Library/Java/JavaVirtualMachines` の探索、Info.plist の `JVMRuntime` など、
JRE を動的に探す仕組みはありません。したがって:

- Homebrew の `openjdk` formula や `temurin` cask を入れても、ステップ 1 で弾かれて起動しない
  （Oracle JRE 無し・Homebrew openjdk 登録済みの Apple Silicon Mac で実行し、終了コード 255、
  Java プロセス未起動を確認済み）
- 起動できるのは java.com 配布の Oracle JRE 8（`/Library/Internet Plug-Ins/JavaAppletPlugin.plugin`）
  を入れた場合だけで、それを提供する Homebrew cask は存在しない
- ブラウザ利用（`JPKI.app`、PKCS#11 モジュール）は Java を一切参照しない

以上から、この tap では Java を `depends_on` にせず、caveats で「通常は不要、必要なら Oracle JRE 8」と
案内しています。新バージョンでランチャーが `java_home` ベースに変わった場合は、`nm -u` と
`otool -tV` で上記を再確認し、caveats を見直してください。

### 公式アンインストーラ（`JPKIUninstall.command`）が消すもの

`/usr/local/lib/JPKI*`、`/Library/Java/Extensions/*JPKI*`、`/Applications/Utilities/JPKI.localized`、
`/Library/LaunchAgents/jp.go.jpki.JPKIUpdateReminder.plist`、`/Applications/JPKI.app`、
Chrome の `jp.go.jpki.json`、そして `pkgutil --forget jp.go.jpki`。
`/etc/e-gov_app/load_path/default.dat` とユーザーのコンテナは残します。

## Cask の設計判断

| stanza | 判断 |
| --- | --- |
| `version "3.9,01-01"` | ファイル名 `JPKIMac_03-09_01-01` の `03-09` がバージョン、`01-01` はビルド番号。3.4.1 は `03-04_01-00`、3.8 は `03-08_01-01` だったので、後半は独立した値としてカンマ区切りで保持する |
| `url` | `version.csv.first` をゼロ埋めして組み立てる。ディレクトリ `101/` は固定値なので、変わったら手で直す |
| `livecheck` | 公式ページ内の `JPKIMac_(\d+)-(\d+)_(\d+-\d+)\.dmg` を全て拾う。HTML コメント内の旧版も拾うが、最大値が採用されるので問題ない |
| `depends_on macos: :ventura` | `LSMinimumSystemVersion` 13.5 に基づく |
| `pkg` + `uninstall pkgutil:` | レシートに記録された全ファイルを Homebrew が削除する。公式アンインストーラと同等 |
| `uninstall delete:` | レシートに無い実行時生成物が残らないよう、公式アンインストーラの `rm -rf` 対象ディレクトリを追加 |
| `uninstall quit:` / `launchctl:` | 更新通知 LaunchAgent と常駐し得るアプリを先に止める |
| `zap` | コンテナと `default.dat*` を削除。`default.dat` は他の電子申請ソフトが参照する共有ファイルなので `uninstall` では触らない |
| `caveats` | `requires_rosetta`（x86_64 専用バイナリのため）、`brew doctor` 警告の説明、ブラウザ設定、Java |
| Java を `depends_on` にしない | ブラウザ利用に Java は不要（公式: Ver 2.4 以降）。Java を使う `JPKIRegistBCA.app` / `JPKIProxySetting.app` の `JavaAppLauncher` は `/Library/Internet Plug-Ins/JavaAppletPlugin.plugin/Contents/Home/bin/java`（Oracle JRE 8）をハードコードしており、Homebrew の `openjdk` / `temurin` では満たせない。公式 cask でも Java は `depends_on` ではなく caveats で案内するのが慣例 |
| `auto_updates` | 付けない。更新通知アプリは「知らせる」だけで自動更新しない |

## 新バージョンが出たときの確認手順

autobump が作る PR、または `brew bump-cask-pr` の後で、以下を確認してください。

```sh
# 1. dmg を取得して中身を見る
brew fetch --cask ttsuru/jpki/jpki
DMG="$(brew --cache --cask ttsuru/jpki/jpki)"
hdiutil attach -nobrowse -readonly -mountpoint /tmp/jpki "$DMG"
ls /tmp/jpki                                  # JPKIInstall.pkg 以外が増えていないか
pkgutil --check-signature /tmp/jpki/JPKIInstall.pkg
spctl -a -vv -t install /tmp/jpki/JPKIInstall.pkg

# 2. ペイロードとスクリプトの差分を見る
pkgutil --expand /tmp/jpki/JPKIInstall.pkg /tmp/jpki-expanded
cat /tmp/jpki-expanded/Distribution | grep -E 'pkg-ref id|version='
ls /tmp/jpki-expanded/JPKIInst.pkg/Scripts
cat /tmp/jpki-expanded/JPKIInst.pkg/Scripts/preinstall   # 書き込み先が増えていないか
(cd /tmp/jpki-expanded/JPKIInst.pkg && cat Payload | gunzip -dc | cpio -idm --quiet)
find /tmp/jpki-expanded/JPKIInst.pkg -maxdepth 4 -not -path '*/Contents/*' | sort   # 配置先の変化
lipo -archs /tmp/jpki-expanded/JPKIInst.pkg/Applications/JPKI.app/Contents/MacOS/JPKI  # arm64 が加わったら requires_rosetta を外す
defaults read /tmp/jpki-expanded/JPKIInst.pkg/Applications/JPKI.app/Contents/Info.plist LSMinimumSystemVersion
hdiutil detach /tmp/jpki

# 3. Cask の検証
brew style --cask ttsuru/jpki/jpki
brew audit --cask --strict --online ttsuru/jpki/jpki
brew livecheck --cask ttsuru/jpki/jpki

# 4. 実機テスト
brew reinstall --cask ttsuru/jpki/jpki
pkgutil --pkg-info jp.go.jpki
# Safari / Chrome でマイナンバーカードの証明書を表示できることを確認
brew uninstall --cask --zap ttsuru/jpki/jpki
```

確認すべき変化と対応:

| 変化 | 対応 |
| --- | --- |
| パッケージ ID が変わった | `uninstall pkgutil:` を更新 |
| LaunchAgent / app の Bundle ID が増減した | `uninstall launchctl:` / `quit:` を更新 |
| `preinstall` が別の場所に書くようになった | `zap` に追加 |
| `JPKI.app` が universal になった | `caveats` から `requires_rosetta` を外す |
| `LSMinimumSystemVersion` が上がった | `depends_on macos:` を更新し README の要件も直す |
| URL のディレクトリ（`101/`）が変わった | `url` を修正 |

## CI

- [tests.yml](../.github/workflows/tests.yml): `push`/`pull_request` で `brew test-bot --only-tap-syntax`
  （readall・style・audit）と actionlint を実行。macOS ジョブでは strict/online audit、livecheck の
  一致確認、チェックサム検証を行い、PR では実際に `brew install --cask` → `brew uninstall --zap` まで通して
  残骸が無いことを確認します。
- [autobump.yml](../.github/workflows/autobump.yml): 毎日 `brew bump --casks --open-pr` を実行し、
  公式サイトに新バージョンがあれば PR を作成します。リポジトリ設定で
  "Allow GitHub Actions to create and approve pull requests" を有効にしてください。
- [dependabot.yml](../.github/dependabot.yml): GitHub Actions の SHA ピンを週次で更新します。
