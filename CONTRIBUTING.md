# Contributing / 貢献ガイド

日本語・英語どちらでも歓迎します。Issues and pull requests in Japanese or English are both welcome.

## 何を受け付けるか / Scope

- 利用者クライアントソフトの新バージョンへの追従（通常は autobump が PR を作ります）
- `uninstall` / `zap` の抜け漏れ、caveats の改善、ドキュメントの修正
- CI の改善

利用者クライアントソフト本体の不具合はこの tap では扱えません。
[J-LIS の窓口](https://www.jpki.go.jp/contact/index.html) へお願いします。

## ローカルでの開発 / Local development

Homebrew の tap は `$(brew --repository)/Library/Taps/<user>/homebrew-<repo>` に置かれます。
作業ディレクトリをそこへシンボリックリンクすると、`brew` コマンドから直接テストできます。

```sh
git clone https://github.com/ttsuru/homebrew-jpki.git
cd homebrew-jpki
mkdir -p "$(brew --repository)/Library/Taps/ttsuru"
ln -s "$PWD" "$(brew --repository)/Library/Taps/ttsuru/homebrew-jpki"
brew trust --tap ttsuru/jpki
```

## バージョン更新の手順 / Bumping the version

1. 公式ページで新しい dmg のファイル名を確認する。例: `JPKIMac_03-10_01-01.dmg` → `version "3.10,01-01"`
2. `brew bump-cask-pr --no-fork --version 3.10,01-01 ttsuru/jpki/jpki` を実行すると、
   ダウンロード・sha256 計算・audit・PR 作成まで自動で行われる
   （手で編集する場合は `version` と `sha256` を書き換える）
3. `url` のディレクトリ `client/download/101/` が変わっていないか確認する
4. 下記のチェックを通す

```sh
brew style --cask ttsuru/jpki/jpki
brew audit --cask --strict --online ttsuru/jpki/jpki
brew livecheck --cask ttsuru/jpki/jpki     # Cask のバージョンと一致すること
brew fetch --cask ttsuru/jpki/jpki         # sha256 が一致すること
brew reinstall --cask ttsuru/jpki/jpki     # 実機で入れ、Safari/Chrome からカードを読めること
brew uninstall --cask --zap ttsuru/jpki/jpki
```

インストーラの構成（配置先ファイル、pre/post install スクリプト）が変わっていないかは
[docs/maintenance.md](docs/maintenance.md) の手順で確認してください。

## コミットメッセージ / Commit messages

Homebrew の慣習に合わせます。

- バージョン更新: `jpki 3.10,01-01`
- それ以外: `jpki: fix zap of load-path file` のように `<token>: <summary>`

## 行動規範 / Code of conduct

[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) に従ってください。
