# RideX — Log Sistemi

Mac/Xcode olmadan hata bulmak zorunda olduğumuz için log **3 katmanlı**.
Biri susarsa diğeri konuşur.

## 1. Bilgisayar (editör)

```text
Godot → proje → Çalıştır (F5)
```

Alt paneldeki **Output** sekmesinde her satır şu formatta:

```
[12:03:45 +  1.24s] [INFO ] [world] sahne hazir
```

Renkler: gri = DEBUG, beyaz = INFO, sarı = WARN, kırmızı = ERROR.

Dosya karşılığı: `%APPDATA%\Godot\app_userdata\RideX\logs\ridex.log`

## 2. Telefon (ekran paneli)

Uygulamanın sol üstünde yarı saydam **LOG** düğmesi var (bilgisayarda **F3**).

Açınca görürsün:

```
FPS 60 | cizim 31 | ucgen 18k | RAM 82MB | 142 satir, 0 uyari, 0 hata
[12:03:45 + 0.02s] [INFO ] [boot] Platform: iOS 18.2
[12:03:45 + 0.05s] [INFO ] [world] sahne hazir
```

- **KOPYALA** → logları panoya alır (WhatsApp/Notlar'a yapıştırabilirsin).
- **TEMIZLE** → sadece ekranı temizler, dosya etkilenmez.

## 3. Telefon (dosya)

Log dosyası: `Dosyalar` uygulaması → **Gözat** → **iPhone'um** → **RideX** → `logs/`

Bu görünürlük, IPA'nın `Info.plist` dosyasına derleme sırasında eklenen
`UIFileSharingEnabled` anahtarıyla açılıyor (CI workflow'unda yapılıyor).

Dosyalar:

| Dosya | İçerik |
|---|---|
| `ridex.log` | Bu oturum |
| `ridex.prev.log` | Bir önceki oturum (çökme analizi için) |

Panoya kopyalayamıyorsan dosyayı dosya uygulamasından paylaş.

## 4. Derleme (GitHub Actions)

Her adım `set -x` ile çalışıyor; tüm çıktı hem konsolda hem artifact'ta:

| Artifact | Ne var |
|---|---|
| `ridex-ipa-unsigned` | İmzalanmamış `.ipa` |
| `build-logs` | `godot-export.log`, `xcodebuild.log`, `xcodebuild.xcresult` |

Derleme patlarsa Actions sayfasındaki adımı aç, ilk `ERROR` satırını oku.
`build-logs` artifact'ını indirip bana yapıştır, yeter.

## Kodda kullanım

```gdscript
Log.section("FAZ 3 - DUNYA")
Log.debug("world", "hdri: %s" % hdri_name)
Log.info("world", "%d prop yuklendi" % count)
Log.warn("vehicle", "tekerlek temasi yok, havada mi?")
Log.error("save", "dosya acilamadi: %s" % path)
```

Kural: **her sistemin giriş/çıkışına en az bir log.** Özellikle:

- sahne yükleme başlangıç/bitiş
- dosya okuma/yazma
- ağ/asset yükleme (varsa)
- fizik/araç spawn
- kullanıcı girdisi (Faz 1'de dokunma)

## Hata ayıklama sırası

1. Ekrandaki paneline bak → son satır ERROR mu?
2. `ridex.log` dosyasını al → tam bağlam.
3. Derleme hatasıysa Actions logu → `xcodebuild.log` içindeki ilk `error:`.
