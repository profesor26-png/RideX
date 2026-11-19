# Faz 1 — Nasıl Yaptık (Tam Kayıt)

> Tarih: 19 Kasım 2026
> Sonuç: Boş bir Godot sahnesi, ücretsiz Apple ID ile iPhone 11'de çalıştı.

---

## 0. Özet

**Ne yaptık:** İçinde oyun olmayan, sadece "RideX" yazısı ve dönen bir küp
bulunan bir uygulamayı iPhone'da açtık.

**Neden:** Oyun yazmadan önce `kod → IPA → imza → telefon` zincirinin
çalıştığını kanıtlamak. Bu zincir kırıksa, 3 hafta oyun yazmanın anlamı yok.

**Sonuç:**

| Ölçüm | Değer |
|---|---|
| Derleme süresi | ~1 dk 20 sn (sıra bekleme hariç) |
| IPA boyutu | 25,1 MB |
| Cihaz | iPhone 11 (iPhone12,1), iOS 26.6 |
| İmza geçerliliği | 7 gün (26 Kasım 2026'ya kadar) |
| Maliyet | 0 TL |

---

## 1. Kısıtlar

| Kısıt | Sonuç |
|---|---|
| Mac yok, sadece Windows | Build GitHub Actions'ta macOS 15'te yapılır |
| App Store yok | Uygulama `.ipa` olarak sideload edilir |
| Her şey ücretsiz | Ücretsiz Apple ID → 7 günlük sertifika |
| iOS 18+ | Developer Mode zorunlu |

---

## 2. Kurulan araçlar

| Araç | Sürüm | Görev |
|---|---|---|
| **Godot** | 4.7.2 | Oyun motoru, proje editörü |
| **Git** | 2.56.0.4 | Sürüm kontrolü |
| **GitHub CLI** | 2.105.0 | Repo + CI + log okuma |
| **iTunes** | 12.13.12.3 | Apple cihaz sürücüleri (Store sürümü DEĞİL) |
| **Apple Mobile Device Support** | 19.4.0.10 | iPhone'u görebilmek için servis |
| **Sideloadly** | 0.60.0 | IPA imzalama + kurulum |

> ⚠️ iTunes'un **Microsoft Store** sürümü Sideloadly ile çalışmaz.
> `winget install Apple.iTunes` doğru olanı kurar.
> Ayrıca `Apple.AppleMobileDeviceSupport` ayrıca kurulmalı — iTunes onu
> her zaman getirmiyor.

---

## 3. Akış

```
   Windows (Godot + Git)
          │
          │  git push origin main
          ▼
   GitHub Actions · macos-15
   ├─ 1. En yeni Xcode'u seç
   ├─ 2. Godot 4.7.2 indir
   ├─ 3. iOS export şablonlarını kur
   ├─ 4. Projeyi import et
   ├─ 5. Xcode projesi üret (Godot export)
   ├─ 6. Info.plist düzenle
   ├─ 7. xcodebuild (İMZASIZ)
   └─ 8. Payload/ → RideX-unsigned.ipa
          │
          │  artifact
          ▼
   Windows (Sideloadly + ücretsiz Apple ID)
          │
          │  imzala + kur
          ▼
       iPhone
```

---

## 4. Proje yapısı

```
RideX/
├── project.godot              # motor ayarları (mobile renderer, ETC2/ASTC)
├── export_presets.cfg         # iOS export ayarları
├── icon.svg                   # uygulama ikonu
├── PLAN.md                    # faz planı
├── scenes/
│   └── main.tscn              # kök sahne (sadece script bağlıyor)
├── scripts/core/
│   ├── log.gd                 # merkezi log (autoload: Log)
│   ├── debug_overlay.gd       # telefondaki log paneli (autoload: DebugOverlay)
│   └── main.gd                # Faz 1 test sahnesi (kod ile kuruluyor)
├── docs/
│   ├── LOGGING.md             # log rehberi
│   ├── INSTALL.md             # kurulum rehberi
│   └── FAZ1-NASIL-YAPILDI.md  # bu dosya
├── dist/
│   └── RideX-unsigned.ipa     # indirilen IPA (git'e girmez)
└── .github/workflows/ios.yml  # CI hattı
```

---

## 5. Log sistemi (en önemli yatırım)

Mac olmadığı için **hiçbir hata ekranda görünmüyordu.** Bu yüzden 4 katman
kurduk:

### Katman 1 — Bilgisayar konsolu
```gdscript
Log.info("world", "sahne hazir")
```
→ `[12:03:45 +  1.24s] [INFO ] [world] sahne hazir`

### Katman 2 — Telefonda ekran paneli
Sol üstteki **LOG** düğmesi (bilgisayarda **F3**):

```
FPS 60 | cizim 31 | ucgen 18k | RAM 82MB | 142 satir, 0 uyari, 0 hata
```

- **KOPYALA** → panoya alır
- **TEMIZLE** → ekranı temizler

### Katman 3 — Telefonda dosya
`Dosyalar → iPhone'um → RideX → logs/ridex.log`

`Info.plist`'e `UIFileSharingEnabled` eklendiği için görünür.
Bir önceki oturum `ridex.prev.log` olarak saklanır (çökme analizi).

### Katman 4 — CI annotation'ları
Derleme patlarsa, workflow hata logunun son 45 satırını **check-run
annotation** olarak yayınlar. Böylece log dosyası indirmeden okunabilir:

```
The following build commands failed:
Undefined symbols for architecture arm64:
```

### Kullanım

```gdscript
Log.section("DUNYA YUKLENIYOR")
Log.debug("sky", "hdri: %s" % name)
Log.info("world", "%d prop yuklendi" % count)
Log.warn("vehicle", "tekerlek temasi yok")
Log.error("save", "dosya acilamadi: %s" % path)
```

**Kural:** her sistemin giriş/çıkışına en az bir log.

---

## 6. CI hattı — adım adım

Dosya: `.github/workflows/ios.yml`

| # | Adım | Ne yapıyor |
|---|---|---|
| 1 | Depoyu al | `actions/checkout` |
| 2 | Ortam bilgisi | macOS/Xcode sürümlerini loglar |
| 3 | **En yeni Xcode'u seç** | `/Applications/Xcode*.app` içinden en yenisini `xcode-select` ile seçer |
| 4 | Godot indir | `Godot_v4.7.2-stable_macos.universal.zip` |
| 5 | Export şablonları | `..._export_templates.tpz` → `~/Library/Application Support/Godot/export_templates/4.7.2.stable/` |
| 6 | Import | `godot --headless --import` |
| 7 | Xcode projesi üret | `godot --headless --export-release "iOS" build/ios` |
| 8 | Info.plist | `UIFileSharingEnabled` + `LSSupportsOpeningDocumentsInPlace` |
| 9 | xcodebuild | `CODE_SIGNING_ALLOWED=NO` → **imzasız** derleme |
| 10 | IPA paketle | `.app` → `Payload/` → zip → `.ipa` |
| 11 | Artifact | `ridex-ipa-unsigned` + `build-logs` |

### Neden imzasız?

Sertifika Windows'ta, ücretsiz Apple ID ile üretiliyor. CI sadece **derliyor**.
İmzalama Sideloadly'de oluyor. Bu sayede CI'da Apple hesabı/secret yok.

---

## 7. Çıkan 6 hata ve çözümleri

Bunlar bir daha yaşanmayacak — hepsi kalıcı düzeltildi.

### Hata 1 — `macos-14` emekliye ayrılmış
```
The configuration 'macos-14-arm64-us-default' is not supported
```
**Sebep:** GitHub, macOS 14 runner'ını 2 Kasım 2026'da kaldırdı.
**Çözüm:** `runs-on: macos-15`

### Hata 2 — Boş hata mesajı
```
ERROR: Cannot export project with preset "iOS" due to configuration errors:
(BOŞ)
```
**Sebep:** Godot kaynağında `has_valid_project_configuration()` şunu yapıyor:
```cpp
if (!ResourceImporterTextureSettings::should_import_etc2_astc()) {
    valid = false;   // hata mesajı EKLEMİYOR
}
```
**Çözüm:** `project.godot` → `textures/vram_compression/import_etc2_astc=true`

### Hata 3 — Team ID zorunlu
```
App Store Team ID not specified.
```
**Sebep:** İmzasız export'ta bile Godot bir takım kimliği istiyor.
**Çözüm:** `application/app_store_team_id="RIDEX00000"` (sahte, imza kullanılmıyor)

### Hata 4 — Xcode sürümü eski
```
Undefined symbols for architecture arm64:
  "_CADynamicRangeAutomatic"
  "_MTLTensorDomain"
```
**Sebep:** Godot 4.7.2 şablonu yeni iOS SDK'sıyla derlenmiş; runner'ın
varsayılan Xcode 16.4'ünde bu semboller yok.
**Çözüm:** Derlemeden önce en yeni Xcode'u seç (adım 3).

### Hata 5 — Sideloadly iPhone'u görmüyor
**Sebep:** `Apple Mobile Device Service` kurulu değildi (iTunes onu getirmedi).
**Çözüm:** `winget install Apple.AppleMobileDeviceSupport` → servis `Running`

### Hata 6 — Log spam
**Sebep:** Fare tekerleği her olayda log satırı yazıyordu.
**Çözüm:** Sadece sol/sağ tık loglanır + 200 ms'de en fazla 1 kayıt.

### Bonus — Kurulum hatası
```
Guru Meditation 0db732@425:3aea77
Login failed (-22406): Enter the correct password
```
**Sebep:** Apple ID şifresi hatalı / çok deneme.
**Çözüm:** 5-10 dk bekle, şifreyi elle dikkatlice gir.

---

## 8. Telefona kurulum (tekrar gerektiğinde)

1. IPA'yı indir: GitHub → Actions → yeşil run → Artifacts →
   `ridex-ipa-unsigned`
2. Sideloadly → IPA'yı sürükle → Apple ID → **Start**
3. Şifre + telefondan gelen 6 haneli kod
4. Telefonda: `Ayarlar → Genel → VPN ve Cihaz Yönetimi →
   Geliştiriciye Güven`
5. **Geliştirici Modu** açık olmalı ve telefon **yeniden başlatılmış** olmalı:
   `Ayarlar → Gizlilik ve Güvenlik → Geliştirici Modu` → aç → reboot →
   açılışta "Aç"

### 7 gün sonra
Sertifika ölür ("RideX artık kullanılamıyor"). Aynı IPA'yı yeniden imzala.
Kayıtlar silinmez, üzerine yazılır.

---

## 9. Komut kopya kağıdı

```powershell
# Derlemeleri listele
gh run list -R profesor26-png/RideX -L 5

# Son derlemeyi izle
gh run watch -R profesor26-png/RideX --compact

# Sadece hatayı gör
gh run view <RUN_ID> -R profesor26-png/RideX --log-failed

# IPA'yı indir
gh run download <RUN_ID> -R profesor26-png/RideX -n ridex-ipa-unsigned -D dist

# Oyunu bilgisayarda çalıştır
& "C:\Users\User\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe" --path .

# Hızlı hata kontrolü (headless)
& "...\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --quit-after 60

# Sadece export'u test et (yerel, Xcode projesi üretmez)
& "...\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --export-release "iOS" build/ios
```

---

## 10. Doğrulama listesi

- [x] Godot projesi hatasız açılıyor
- [x] Log paneli çalışıyor
- [x] Dokunma loglanıyor
- [x] GitHub'a push → CI otomatik çalışıyor
- [x] CI imzasız IPA üretiyor
- [x] Sideloadly cihazı görüyor
- [x] Apple ID ile imzalama başarılı
- [x] Telefonda uygulama açılıyor
- [x] Geliştirici Modu + güven adımları çözüldü

---

## 11. Sırada — Faz 2

| İş | Detay |
|---|---|
| Araç fiziği | Raycast vehicle: gaz, fren, dönüş, süspansiyon |
| Kamera | Takip + omuz + sinema, hıza göre FOV |
| Kontrol | Dokunmatik gaz/fren + direksiyon, tilt opsiyonu |
| Test haritası | Düz zemin + birkaç engel |
| HUD | Hız göstergesi |

**Faz 2 kabul kriteri:** Telefonda sürmek zevkli, 60 FPS.
