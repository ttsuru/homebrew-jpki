<!-- 日本語 / English どちらでも構いません。 -->

## 変更内容 / What

<!-- 例: jpki 3.10,01-01 へ更新 -->

## 確認したこと / Checklist

- [ ] `brew style --cask ttsuru/jpki/jpki`
- [ ] `brew audit --cask --strict --online ttsuru/jpki/jpki`
- [ ] `brew livecheck --cask ttsuru/jpki/jpki`（表示されるバージョンが Cask と一致する）
- [ ] `brew fetch --cask ttsuru/jpki/jpki`（sha256 が一致する）
- [ ] バージョン更新の場合: `brew reinstall --cask ttsuru/jpki/jpki` で実機インストールし、Safari/Chrome からマイナンバーカードを読めることを確認した
- [ ] 必要に応じて README / docs を更新した
