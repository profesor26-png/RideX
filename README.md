# RideX

iOS için 3D serbest sürüş motor oyunu. App Store yok — uygulama `.ipa` olarak
sideload edilir. Sıfır bütçe.

## Durum

| Faz | Durum |
|---|---|
| Faz 1 — Pipeline (kod → IPA → telefon) | ✅ tamamlandı |
| Faz 2 — Sürüş çekirdeği | 🔜 sırada |

## Hızlı bakış

- **Motor:** Godot 4.7.2 (Mobile renderer, Metal)
- **Build:** GitHub Actions · `macos-15` · imzasız `.ipa`
- **Kurulum:** Sideloadly + ücretsiz Apple ID (7 günlük imza)
- **Hedef cihaz:** iPhone 11 ve üstü, iOS 18+

## Belgeler

| Dosya | İçerik |
|---|---|
| [`PLAN.md`](PLAN.md) | Faz planı, kısıtlar, mimari |
| [`docs/FAZ1-NASIL-YAPILDI.md`](docs/FAZ1-NASIL-YAPILDI.md) | Faz 1'in tam kaydı + çıkan 6 hata ve çözümleri |
| [`docs/INSTALL.md`](docs/INSTALL.md) | iPhone'a kurulum rehberi |
| [`docs/LOGGING.md`](docs/LOGGING.md) | Log sistemi (4 katman) |

## Geliştirme

```bash
# yerelde çalıştır
godot --path .

# hata kontrolü
godot --headless --path . --quit-after 60

# derlemeyi tetikle
git push origin main

# IPA indir
gh run download <RUN_ID> -n ridex-ipa-unsigned -D dist
```

## Log

```gdscript
Log.section("DUNYA")
Log.info("world", "sahne hazir")
Log.warn("vehicle", "tekerlek temasi yok")
Log.error("save", "dosya acilamadi")
```

Telefonda sol üstteki **LOG** düğmesi paneli açar.
