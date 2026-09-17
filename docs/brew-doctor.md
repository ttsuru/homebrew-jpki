# `brew doctor` の「Unbrewed dylibs」警告について

## 症状

利用者クライアントソフトをインストールすると（この tap 経由でも、公式 dmg からの手動でも同じ）、
`brew doctor` が次のように報告します。

```text
Warning: Unbrewed dylibs were found in /usr/local/lib.
If you didn't put them there on purpose they could cause problems when
building Homebrew formulae and may need to be deleted.

Unexpected dylibs:
  /usr/local/lib/JPKIPKCS11.dylib
  /usr/local/lib/JPKIPKCS11Auth.dylib
  /usr/local/lib/JPKIPKCS11Sign.dylib
  /usr/local/lib/JPKIServiceAPI.dylib
```

## 原因

`brew doctor` の `check_for_stray_dylibs` は `/usr/local/lib/*.dylib` を列挙し、
Homebrew が管理していないファイルを許可リスト（MacFUSE、NTFS-3G、SentinelOne など）と
突き合わせて警告します（[diagnostic.rb](https://github.com/Homebrew/brew/blob/HEAD/Library/Homebrew/diagnostic.rb)）。
JPKI の 4 ファイルは許可リストに無いので警告されます。

利用者クライアントソフトがこの場所に置く理由は仕様上のものです。

- インストーラの `preinstall` スクリプトは `/etc/e-gov_app/load_path/default.dat` に
  次の内容を書き込みます。

  ```ini
  name=JPKI_Appli-01
  pathSign=/usr/local/lib/JPKIPKCS11Sign.dylib
  pathAuth=/usr/local/lib/JPKIPKCS11Auth.dylib
  ```

  e-Tax などの電子申請ソフトはこのロードパスファイルを読んで PKCS#11 モジュールを見つけます。
  J-LIS が公開している
  「利用者クライアントソフト API 仕様書【カード AP ライブラリ PKCS#11 編】」
  （[J-LIS 技術仕様ページ](https://www.j-lis.go.jp/jpki/procedure/procedure1_2_3.html)）が
  このインターフェースを定めています。
- したがって Cask 側でファイルを別の場所へ移したりシンボリックリンクに置き換えたりすると、
  他のアプリからモジュールが見つからなくなる恐れがあり、利用条件（改造禁止）にも抵触します。

## 影響

実害はありません。警告文にある「building Homebrew formulae」への影響は、
Homebrew の prefix が `/usr/local` の Intel Mac で、かつビルド対象が `JPKIPKCS11` などの名前を
リンクしようとした場合に限られ、現実には起こりません。Apple Silicon（prefix `/opt/homebrew`）では
`/usr/local/lib` はビルドのリンクパスにすら含まれません。

## 根本対処: Homebrew 本体の許可リストへ追加する

許可リストは Homebrew 本体（`Homebrew/brew`）にあり、tap から変更できません。
このリポジトリの [patches/homebrew-brew-diagnostic-allow-jpki-dylibs.patch](../patches/homebrew-brew-diagnostic-allow-jpki-dylibs.patch)
はそのための変更で、次の手順で upstream へ提案できます。

```sh
cd "$(brew --repository)"
git checkout -b jpki-dylibs origin/main
git am /path/to/homebrew-jpki/patches/homebrew-brew-diagnostic-allow-jpki-dylibs.patch
brew style Library/Homebrew/diagnostic.rb
brew tests --only=diagnostic
gh pr create --repo Homebrew/brew --fill
```

マージされるまでの間、手元で警告を消したいだけなら同じパッチをローカルの Homebrew に当てても
構いませんが、`brew update` で上書きされます。

## 代替案として却下したもの

| 案 | 却下理由 |
| --- | --- |
| Cask の `postflight` で dylib を Caskroom へ移し、`/usr/local/lib` にシンボリックリンクを置く（`brew doctor` はシンボリックリンクを無視する） | 公証済みインストーラの配置を改変することになり、他アプリからの読み込みやコード署名の検証に影響し得る。利用条件の「改造禁止」にも触れる |
| `caveats` で警告を予告するだけ | 実施済み。ただし根本対処ではない |
| `brew doctor` を使わない | 他の有用な診断まで失う |
