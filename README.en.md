# homebrew-jpki

[日本語](README.md)

A third-party [Homebrew](https://brew.sh/) tap for the
[JPKI User Client Software for Mac](https://www.jpki.go.jp/download/mac.html)
(公的個人認証サービス 利用者クライアントソフト), the software required to use the
My Number Card's digital certificates with e-Tax and other Japanese e-government services.

Upstream only offers a manual `.dmg` download. This tap wraps that installer in a cask so that you can:

- download the installer from the official URL with SHA-256 verification,
- follow new releases with `brew upgrade` (the tap runs `livecheck` daily and opens a bump PR automatically),
- remove it with `brew uninstall`, matching the vendor's uninstaller, or `--zap` for a full clean-up.

> **Note** This tap does not redistribute the software. The cask points at the official download URL;
> the software itself is governed by J-LIS's
> [terms of use](https://www.jpki.go.jp/download/mac.html).

## Requirements

| | |
| --- | --- |
| macOS | 13 Ventura or later (`LSMinimumSystemVersion` of the app is 13.5). Upstream verifies only the two latest releases |
| CPU | Intel, or Apple Silicon with Rosetta 2 (`JPKI.app` and `JPKIUtility.app` are x86_64-only) |
| Homebrew | 6.0 or later (tap trust) |
| Other | An IC card reader and a My Number Card |

## Install

```sh
brew install --cask ttsuru/jpki/jpki
```

Using the fully-qualified name trusts only this cask. To trust the whole tap and use the short name:

```sh
brew tap ttsuru/jpki
brew trust --tap ttsuru/jpki
brew install --cask jpki
```

The installer is a signed and notarized `.pkg` that writes to `/Applications`, `/Library` and
`/usr/local/lib`, so you will be asked for your administrator password. When it finishes, the
vendor's post-install script opens Finder and the "update reminder settings" app; that is upstream behaviour.

If you already installed it manually from the official dmg, just run the command above. The package
identifier (`jp.go.jpki`) is the same, so the Apple installer treats it as an upgrade and Homebrew
manages it from then on.

## After installing

- **Safari**: enable the **JPKI** extension in Safari > Settings > Extensions.
- **Chrome**: add the **JPKI利用者ソフト** extension from the Chrome Web Store.
- **Java is normally not needed.** Since Ver 2.4 browser use does not require a JRE. Only
  `JPKIRegistBCA.app` ("register with the Java runtime") and `JPKIProxySetting.app` use Java, and they
  hard-code Oracle's JRE 8 from [java.com](https://www.java.com/) at
  `/Library/Internet Plug-Ins/JavaAppletPlugin.plugin`; Homebrew's `openjdk` or `temurin` are not
  detected, so this tap does not declare a Java dependency. Install it only if the e-application
  service you use requires the Java interface (see the
  [official JRE guide](https://www.jpki.go.jp/e-apply/jre.html)).

## Upgrade

```sh
brew update && brew upgrade --cask jpki
```

## Uninstall

```sh
brew uninstall --cask jpki          # same as the vendor's JPKIUninstall.command
brew uninstall --cask --zap jpki    # also removes containers and the PKCS#11 load-path file
```

## About the `brew doctor` warning

After installation `brew doctor` reports the four `JPKI*.dylib` files in `/usr/local/lib` as
"Unbrewed dylibs". This is harmless and cannot be avoided by the cask: the J-LIS API specification
fixes the PKCS#11 module location, and other applications resolve it through
`/etc/e-gov_app/load_path/default.dat`. A patch that adds them to Homebrew's allow list is kept in
[patches/](patches/); see [docs/brew-doctor.md](docs/brew-doctor.md).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and [docs/maintenance.md](docs/maintenance.md).
Report vulnerabilities as described in [SECURITY.md](SECURITY.md).

## License

The tap (cask, docs, CI) is released under the [MIT License](LICENSE). The JPKI software is
copyrighted by the Japan Agency for Local Authority Information Systems and is not part of this repository.
