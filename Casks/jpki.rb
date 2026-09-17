cask "jpki" do
  # The upstream file name encodes the version as "MM-mm" plus a build suffix,
  # e.g. JPKIMac_03-09_01-01.dmg => version 3.9, build 01-01.
  version "3.9,01-01"
  sha256 "ee7eddf29860eacd7406c91c5113c32a11e51a0e0a8abda387dd728f43255d80"

  url "https://www.jpki.go.jp/client/download/101/JPKIMac_#{version.csv.first.major.rjust(2, "0")}-#{version.csv.first.minor.rjust(2, "0")}_#{version.csv.second}.dmg"
  name "JPKI User Client Software"
  name "公的個人認証サービス 利用者クライアントソフト"
  desc "Digital signature and authentication client for the My Number Card (JPKI)"
  homepage "https://www.jpki.go.jp/"

  livecheck do
    url "https://www.jpki.go.jp/download/mac.html"
    regex(/JPKIMac_(\d+)-(\d+)_(\d+-\d+)\.dmg/i)
    strategy :page_match do |page, regex|
      page.scan(regex).map { |match| "#{match[0].to_i}.#{match[1].to_i},#{match[2]}" }
    end
  end

  # LSMinimumSystemVersion of JPKI.app is 13.5. Upstream officially verifies only
  # the two most recent macOS releases, always on Intel hardware.
  depends_on macos: :ventura

  pkg "JPKIInstall.pkg"

  uninstall launchctl: "jp.go.jpki.JPKIUpdateReminder",
            quit:      [
              "jp.go.jpki",
              "jp.go.jpki.JPKIUpdateReminderMain",
              "jp.go.jpki.JPKIUpdateReminderSetting",
              "jp.go.jpki.JPKIUserCertServiceMain",
              "jp.go.jpki.JPKIUtility",
            ],
            pkgutil:   "jp.go.jpki",
            # Mirrors the vendor's JPKIUninstall.command for anything the
            # receipt does not cover (runtime-created files inside these dirs).
            delete:    [
              "/Applications/Utilities/JPKI.localized",
              "/usr/local/lib/JPKI",
            ]

  # The installer's preinstall script writes the PKCS#11 "load path" file
  # /etc/e-gov_app/load_path/default.dat (name=JPKI_Appli-01, pathSign,
  # pathAuth) and rotates older copies to default.dat1..17 / default.dat_bk.
  # Other e-Government client software reads it to locate the JPKI module and
  # the vendor uninstaller leaves it in place, so it is only removed on zap.
  zap delete: "/private/etc/e-gov_app/load_path/default.dat*",
      trash:  [
        "~/Library/Containers/jp.go.jpki",
        "~/Library/Containers/jp.go.jpki.jpkiSafariAppExtension",
        "~/Library/Group Containers/LQF3UNS9HK.jp.go.jpki",
      ],
      rmdir:  "/private/etc/e-gov_app"

  caveats do
    # JPKI.app (the browser native-messaging host) and JPKIUtility.app ship
    # x86_64-only executables even though the PKCS#11 dylibs are universal.
    requires_rosetta
    <<~EOS
      The installer places the PKCS#11 modules in /usr/local/lib, as mandated by
      the J-LIS API specification. `brew doctor` therefore reports them as
      "Unbrewed dylibs"; this is harmless. See:
        https://github.com/ttsuru/homebrew-jpki/blob/main/docs/brew-doctor.md

      After installation:
        - Safari: enable the "JPKI" extension in Safari > Settings > Extensions.
        - Chrome: install the "JPKI利用者ソフト" extension from the Chrome Web Store.
        - Java is NOT required for browser use. Only "Java実行環境への登録"
          (JPKIRegistBCA.app) and JPKIProxySetting.app need it, and they look
          for Oracle's JRE 8 from https://www.java.com/ at
          /Library/Internet Plug-Ins/JavaAppletPlugin.plugin (OpenJDK/Temurin
          installs are not found). Install it only if your e-application
          service requires the Java interface.
    EOS
  end
end
