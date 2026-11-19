# RideX — iPhone'a Kurulum Rehberi

App Store yok. Uygulama `.ipa` olarak, ücretsiz Apple ID ile imzalanıp kurulur.
**Sertifika 7 gün geçerlidir**, sonra yeniden imzalamak gerekir.

---

## 0. Bir kereye mahsus hazırlık

| Gereken | Kontrol |
|---|---|
| iTunes (masaüstü sürümü) | Kurulu olmalı — **Microsoft Store sürümü olmaz** |
| Sideloadly | Kurulu olmalı |
| iPhone + veri kablosu | Bağlı, "Bu bilgisayara güven" onaylı |
| Apple ID | iPhone'da kullandığın hesap |
| iOS 16+ | Developer Mode açık olmalı (aşağıda) |

### 0.1 iPhone'da Developer Mode açma (iOS 18'de zorunlu)

1. Telefonu **kaboyla bilgisayara** bağla
2. Telefonda **Ayarlar → Gizlilik ve Güvenlik**
3. En alta in → **Geliştirici Modu** → aç
4. Telefon **yeniden başlar**
5. Açılışta "Geliştirici Modu'nu açmak istiyor musunuz?" → **Aç** → parola

> Bu seçenek görünmüyorsa: aygıtı bir kez bilgisayara bağlayıp Xcode/iTunes'un
> görmesi gerekir. Sideloadly ile bir kurulum denedikten sonra görünür.

### 0.2 Bilgisayar telefonu görüyor mu?

Sideloadly'yi aç → üstte **"Device"** kısmında iPhone'un adı görünmeli.
Görünmüyorsa:

- Kabloyu çıkar tak
- Telefonda "Bu Bilgisayara Güven" → **Güven**
- iTunes açıkken telefonun göründüğünü kontrol et

---

## 1. IPA'yı indir

1. GitHub'da repoya git: `github.com/profesor26-png/RideX/actions`
2. En üstteki **yeşil tikli** build'e gir
3. Sayfanın altındaki **Artifacts** bölümü
4. **`ridex-ipa-unsigned`** dosyasını indir (zip iner)
5. Zip'i aç → içinde `RideX-unsigned.ipa` var

> Yeşil tik yoksa derleme patlamıştır. **`build-logs`** artifact'ını indirip
> bize ver, birlikte bakalım.

---

## 2. Sideloadly ile kur

1. **Sideloadly**'yi aç
2. **IPA** kutusuna `RideX-unsigned.ipa` dosyasını sürükle
3. **Apple ID** kutusuna Apple ID'ni yaz
4. **Start** butonuna bas
5. Apple ID şifresini gir
6. Telefonuna **6 haneli doğrulama kodu** gelirse yaz
7. "Done" yazısını gör

### Sık karşılaşılan hatalar

| Hata | Çözüm |
|---|---|
| `Unable to install ... A valid provisioning profile` | Apple ID'de 2FA açık olmalı; Sideloadly'de "Advanced Options" → yeni bundle ID |
| `The maximum number of apps has been reached` | Ücretsiz hesapta 3 uygulama sınırı. Eski birini sil |
| `Your device is not registered` | Cihazı bağla, Sideloadly'de Refresh Device List |
| `Anisette data not found` | Sideloadly'yi yönetici olarak çalıştır |
| Kurulum %70'te takılıyor | iTunes açık olsun, kabloyu değiştir |

---

## 3. Uygulamayı açma (ilk sefer)

iOS, kendi imzalanmamış uygulamaları "güvenilmeyen geliştirici" sayar:

1. **Ayarlar → Genel → VPN ve Cihaz Yönetimi**
2. **Geliştirici Uygulaması** altında Apple ID'n görünür
3. Ona dokun → **"Geliştiriciye Güven"** → **Güven**

Sonra ana ekranda **RideX** ikonuna bas. Açılmalı.

> "Güven" seçeneği yoksa Developer Mode kapalıdır (bkz. 0.1).

---

## 4. Logları görme (sorun çıkarsa)

**Yöntem A — ekrandan:** Uygulamada sol üstteki **LOG** düğmesi →
son satırlar. **KOPYALA** → WhatsApp/Notlar'a yapıştır → bana gönder.

**Yöntem B — dosyadan:** `Dosyalar` → `Gözat` → `iPhone'um` → `RideX` →
`logs` → `ridex.log` → paylaş.

**Yöntem C — WiFi ile:** Sideloadly'de "Device" altında log yok; ama
uygulama çökerse iPad/iPhone'da **Ayarlar → Gizlilik → Analiz ve İyileştirmeler
→ Analiz Verileri** içinde `RideX-...ips` dosyası olur.

---

## 5. 7 gün sonra: yeniden imza

Süre dolunca uygulama açılmaz ("RideX artık kullanılamıyor").

1. Sideloadly'yi aç
2. Aynı IPA'yı sürükle, aynı Apple ID
3. **Start**
4. Telefon açık ve bağlı olsun

Eski uygulama silinmez, üzerine yazılır. Kayıtlar korunur.

> Bu işi her hafta yapmamak için ileride **ücretli developer hesabı** ($99/yıl,
> 1 yıl geçerli) tek gerçek çözüm. Şimdilik ücretsiz yolla devam.

---

## 6. Kontrol listesi (Faz 1 kabul)

- [ ] CI yeşil, IPA indirildi
- [ ] Sideloadly "Done" dedi
- [ ] Telefonda RideX ikonu var
- [ ] Geliştiriciye güven verildi
- [ ] Uygulama açıldı, "RideX" yazısı göründü
- [ ] LOG düğmesi çalışıyor
- [ ] Ekrana dokununca logda `[input] dokunma` satırı düşüyor
