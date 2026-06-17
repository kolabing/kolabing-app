<!--
  Bu template ZORUNLUDUR. Her başlığı doldurmadan PR "hazır" sayılmaz.
  Boş bıraktığın başlıkları silme — "Yok / Gerekmiyor" yaz.
  Bu bir MOBILE (Flutter) reposudur: iOS + Android birlikte düşünülmeli.
-->

## 🎯 Bu feature'da ne yapıldı?
<!-- Bu PR neyi değiştiriyor? Kısa ve net, madde madde. -->



## 🐞 Hangi sorunu çözdük?
<!-- Hangi bug / ihtiyaç / talep için yapıldı? Varsa issue linki: Closes #__ -->



## 🚀 Production'da çalışması için gereken değişiklikler
<!--
  Merge sonrası prod'da çalışması için NE gerekiyor? Yoksa "Ekstra değişiklik gerekmiyor" yaz.
  - [ ] Yeni env / secret: ____
  - [ ] Backend deploy / migration / yeni endpoint canlıda olmalı: ____
  - [ ] App Store / Play Store build alınmalı (versiyon/build no: ____)
  - [ ] Feature flag / remote config: ____
-->



## 📱 Bu iş için mobilde hangi branch merge edilmeli?
<!-- Bağımlılık varsa yaz. Yoksa "Sadece bu branch". -->

- Base branch: `master`
- Bağımlı branch(ler): ____

## 🧪 Bu merge nasıl test edilir? (reviewer adım adım çalıştırabilsin)
<!-- Reviewer'ın senin değişikliğini cihazda doğrulayabilmesi için NET adımlar. -->

- **Etkilenen rol:** Business / Community / Attendee (ilgili olanı bırak)
- **Test hesabı / data:** ____
- **Adımlar:**
  1.
  2.
  3.
- **Beklenen sonuç:** ____

## 📸 Ekran görüntüsü / video (ZORUNLU — UI'a dokunan her PR'da)
<!--
  En az 1 görsel ekle. UI değiştiyse before/after koy.
  Mümkünse hem iOS hem Android. UI değişikliği yoksa "UI değişikliği yok" yaz.
-->

| Before | After |
| ------ | ----- |
|        |       |

---

## ✅ Definition of Done (kapatmadan kontrol et)
- [ ] `flutter analyze` temiz (yeni error/warning eklemedim)
- [ ] Değişen dosyalara `dart format` uygulandı
- [ ] **iOS** simülatör/cihazda denendi
- [ ] **Android** emülatör/cihazda denendi
- [ ] Kullanıcıya görünen yeni metinler i18n'de var (`app_en.arb` + `app_es.arb` + `app_ca.arb`) ve `flutter gen-l10n` çalıştırıldı
- [ ] Hardcode yok (base URL / ID / email / şehir-kategori listesi — hepsi API'den)
- [ ] `BACKLOG.md` güncellendi (biten iş çıkarıldı / yeni bug eklendi)

## 🤖 AI ile mi yazıldı?
<!-- Hangi tool + ne yaptırdın? Sorumluluk sende kalır, sorun değil — sadece şeffaf ol. -->

