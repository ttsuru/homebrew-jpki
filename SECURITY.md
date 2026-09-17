# Security Policy / セキュリティポリシー

## 対象 / Scope

この tap が扱うのは「公式 URL からのダウンロード」「SHA-256 検証」「インストール・削除の定義」です。
次のような問題は、この tap の脆弱性として報告してください。

- Cask の `url` が公式サイト以外を指している、`sha256` が公式配布物と一致しない
- `uninstall` / `zap` が JPKI と無関係なファイルを削除する
- CI ワークフローの権限や依存アクションの問題

利用者クライアントソフト本体の脆弱性は、この tap では対応できません。
地方公共団体情報システム機構（J-LIS）の [お問い合わせ窓口](https://www.jpki.go.jp/contact/index.html) へ報告してください。

## 報告方法 / Reporting

GitHub の [Private vulnerability reporting](https://github.com/ttsuru/homebrew-jpki/security/advisories/new)
から報告してください。公開 Issue には書かないでください。

Please use GitHub's private vulnerability reporting for anything that could put users at risk.
Do not open a public issue.

## 検証の仕組み / How integrity is ensured

- Cask の `sha256` は、公式サイトから取得した dmg に対して計算した値です。
  Homebrew はダウンロード後に必ずこの値と照合し、一致しなければインストールしません。
- dmg 内の `JPKIInstall.pkg` は Apple の Developer ID で署名・公証されています
  （Team ID `LQF3UNS9HK`、Japan Agency for Local Authority Information Systems）。
  更新時は `pkgutil --check-signature` と `spctl -a -t install` で確認します。
- CI では `brew audit --online` により、URL が到達可能でチェックサムが一致することを検証しています。
