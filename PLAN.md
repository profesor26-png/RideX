# RideX — iOS Motor Oyunu (Serbest Sürüş)

> Sürüm: 0.1 — Planlama aşaması
> Tarih: 2026-11-19

---

## 1. Proje Özeti

iPhone'da oynanan, 3D serbest sürüş motor oyunu. App Store'a çıkmayacak;
uygulama doğrudan **`.ipa`** olarak cihaza kurulacak. İlk sürümde amaç yok,
sadece sürüş hissi ve keşif. Görev/yarış sistemi ileride eklenebilir.

## 2. Kısıtlar ve Kesinleşen Kararlar

| Konu | Karar |
|---|---|
| Platform | iOS 18+ |
| Test cihazı | iPhone 11 ve üstü |
| Dağıtım | App Store yok, `.ipa` sideload |
| Bütçe | **Her şey $0** (tek kural) |
| Oyun döngüsü | Şimdilik saf serbest sürüş, görevler ileride |
| Görsel hedef | Ücretsiz varlıklarla ulaşılabilen **en iyi** görüntü (stilize-gerçekçi) |
| Geliştirme makinesi | Windows (Mac yok) |

### 2.1 Kaçınılmaz sonuçlar

1. **7 günlük imza.** Ücretsiz Apple ID ile kurulan uygulamanın sertifikası
   7 gün sonra geçersiz olur → haftada bir yeniden imza (Sideloadly, ~2 dk).
2. **iOS 18 Developer Mode zorunlu** (Ayarlar → Gizlilik ve Güvenlik).
3. **Aynı anda 3 uygulama** limiti, haftada 10 App ID.
4. **Build macOS üzerinde olmak zorunda** → GitHub Actions macOS runner.
5. **"Fotogerçekçi" ulaşılamaz.** Hedef: HDRI + PBR + doğru ışık/gölge ile
   "bu bedava mı?" dedirten stilize-gerçekçi görüntü.

## 3. Teknoloji Yığını

| Katman | Seçim | Neden |
|---|---|---|
| Oyun motoru | **Godot 4.4+** (Mobile renderer, Metal) | MIT lisans, Windows'ta editör, CI'da lisans derdi yok |
| Dil | GDScript | Hızlı iterasyon, motorla tam uyum |
| Build | GitHub Actions macOS runner | Bedava, tekrarlanabilir |
| İmzalama | Sideloadly (Windows) + ücretsiz Apple ID | Bedava tek pratik yol |
| Sürüm kontrolü | Git + GitHub (public repo) | CI dakikaları bedava |
| Görev takibi | `PLAN.md` + fazlar | Tek kişilik disiplin |

**Neden Unity değil?** Lisans aktivasyonu ve CI kurulumu Godot'a göre çok daha
kırılgan. Bedava gerçekçi asset konusunda Unity önde, ama build sürtünmesi
"her şey free" kuralıyla çakışıyor.

## 4. Ücretsiz Varlık Kaynakları

| Kaynak | İçerik | Lisans |
|---|---|---|
| Poly Haven | HDRI, materyal, model | CC0 |
| ambientCG | PBR materyal | CC0 |
| Quaternius | Düşük poligon araç/çevre | CC0 |
| Kenney | Prop, UI, ses | CC0 |
| Poly Pizza | Model | CC0 |
| Sketchfab (CC0 filtresi) | Model | CC0 |
| Freesound (CC0 filtresi) | Ses | CC0 |
| Mixamo | Animasyon | Ücretsiz |

**Kural:** Her varlık repoya eklenmeden önce lisansı `assets/CREDITS.md`'ye
yazılır. CC0 dışında bir şey kullanılırsa atıf zorunlu.

## 5. Mimari

### 5.1 Klasör yapısı

```
RideX/
├── project.godot
├── export_presets.cfg
├── PLAN.md
├── .github/workflows/ios.yml
├── scenes/
│   ├── main.tscn            # kök sahne
│   ├── vehicle/             # motor, teker, kamera
│   ├── world/               # yol, arazi, prop
│   └── ui/                  # HUD, menü
├── scripts/
│   ├── vehicle/
│   ├── world/
│   └── ui/
├── assets/
│   ├── models/  textures/  audio/  hdri/
│   └── CREDITS.md
└── build/                   # .gitignore'da
```

### 5.2 Ana sistemler

- **Vehicle** — raycast tabanlı araç fiziği (`VehicleBody3D` yerine özel
  raycast controller: daha öngörülebilir, motor oyununa daha uygun).
- **CameraRig** — yay kol + 3 mod: takip / omuz / sinema. Hıza göre FOV.
- **World** — yol spline (`Path3D`), arazi mesh'i, LOD'lu prop'lar.
- **Audio** — motor sesi devirle pitch-shift, rüzgâr katmanı, çarpma one-shot.
- **Input** — dokunmatik butonlar + tilt (jiroskop) seçeneği.
- **Save** — `ConfigFile`: ayarlar, en iyi hız, son konum.
- **Settings** — grafik kalitesi (Düşük/Orta/Yüksek), FPS göstergesi.

### 5.3 Performans hedefleri (iPhone 11 taban)

| Metrik | Hedef |
|---|---|
| FPS | 60 (düşerse 30'a kilit) |
| Render çözünürlüğü | Dinamik ölçekleme (0.7–1.0) |
| Draw call | < 150 |
| Sahne poligonu | < 400k (görünen) |
| Bellek | < 700 MB |
| IPA boyutu | < 150 MB |

Ayarlar: MSAA kapalı, FXAA açık, SSAO kapalı (materyalde baked AO),
gölge atlası 2048, glow düşük, TAA kapalı.

## 6. Faz Planı

Kural: **Her fazın sonunda telefonda oynanabilir/çalışan bir sürüm olacak.**

### ✅ Faz 0 — Kararlar
Tür, stil, motor, imza yolu, cihaz hedefi belirlendi.

### 🔜 Faz 1 — Pipeline Kanıtı
**Amaç:** Sıfır oyun kodu. Sadece "kod → IPA → telefon" zincirinin çalıştığını kanıtla.

Adımlar:
1. Godot 4.x'i Windows'a kur, proje oluştur (`com.ridex.game`).
2. Test sahnesi: düz zemin + kamera + "RideX" yazısı.
3. Git + GitHub public repo.
4. `.github/workflows/ios.yml`: Godot export → `xcodebuild` (imzasız) → `.ipa` artifact.
5. Push → Actions → `RideX-unsigned.ipa` indir.
6. Windows'a Sideloadly + iTunes (Microsoft Store dışı sürüm) kur.
7. iPhone: Developer Mode aç → kabloyla bağla → Sideloadly ile imzala + kur.
8. Ayarlar → Genel → VPN ve Cihaz Yönetimi → geliştiriciye güven → aç.

**Kabul kriteri:** Telefonda uygulama açılıyor ve sahne görünüyor.
Ayrıca "tek tıkla IPA" akışı dokümante edilmiş oluyor.

**Tahmini süre:** 1–2 gün (en riskli faz, %80 burada takılırız).

### Faz 2 — Sürüş Çekirdeği
- Tek motor, düz boş harita
- Gaz / fren / dönüş, raycast araç fiziği
- 3 kamera modu, hıza göre FOV
- Dokunmatik kontroller + tilt seçeneği
- Yer tutucu kutu grafikler

**Kabul:** "Sürmek zevkli" hissi. 60 FPS.

### Faz 3 — Dünya
- Yol spline'ı + arazi
- HDRI gökyüzü, güneş/gölge
- Binalar, ağaçlar, prop (LOD'lu)
- Basit trafik (spline üzerinde hareket)
- 3–4 km'lik döngü yol

**Kabul:** Kesintisiz turlanabilen, 60 FPS bir harita.

### Faz 4 — Hissiyat
- Motor sesi (devir → pitch), rüzgâr katmanı
- Hız bulanıklığı, lastik izi, çarpma efekti
- Kamera sarsıntısı, titreşim (haptik)
- Ekran içi hız göstergesi

**Kabul:** Grafik kapalıyken bile "oyun gibi" hissettiriyor.

### Faz 5 — Döngü ve İçerik
- HUD + minimap
- 2–3 motor, basit garaj
- Kayıt sistemi, ayarlar menüsü, grafik kalitesi
- (İleride) checkpoint görevleri

**Kabul:** Oyuncu 20+ dakika kendi kendine oyalanabiliyor.

### Faz 6 — Cila ve Dağıtım
- Menü/animasyon cilası, yükleme ekranı
- Optimizasyon (draw call, LOD, doku boyutu)
- IPA'nın arşivlenmesi + kurulum rehberi
- Sürüm notları

## 7. Riskler ve Önlemler

| Risk | Etki | Önlem |
|---|---|---|
| GitHub Actions'ta Godot iOS export patlar | Yüksek | Faz 1'de erken test; Godot sürümünü sabitle |
| Sideloadly/Apple ID 2FA sorunu | Yüksek | iTunes sürümü doğru kurulacak; uygulamaya özel şifre hazır |
| iPhone 11'de FPS düşük | Orta | Dinamik çözünürlük + kalite ayarı Faz 3'te |
| Free asset kalitesi yetmez | Orta | Stilize-gerçekçi hedef; materyal/ışıkla kapat |
| 7 günlük imza unutulur | Düşük | Takvim hatırlatıcısı + rehber |
| Kapsam büyür, bitmez | Yüksek | Faz kapıları: kabul kriteri geçmeden ilerleme yok |

## 8. Haftalık Bakım

- Her 7 günde bir Sideloadly ile yeniden imza (2 dk).
- IPA arşivini `build/` altında tut, son çalışan sürümü sakla.
- Her faz sonunda `NOTES.md`'ye "ne değişti" yaz.

## 9. Sıradaki Adım

**Faz 1.** Kod yazmadan önce Godot kurulumu ve GitHub Actions iskeleti.
