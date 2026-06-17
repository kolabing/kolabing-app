<!--
  Bu template ZORUNLUDUR. Her başlığı doldurmadan PR "hazır" sayılmaz.
  Boş bıraktığın başlıkları silme — "Yok / Gerekmiyor" yaz.
-->

## 🎯 Bu feature'da ne yapıldı?
<!-- Bu PR neyi değiştiriyor? Kısa ve net, madde madde. -->



## 🐞 Hangi sorunu çözdük?
<!-- Hangi bug / ihtiyaç / talep için yapıldı? Varsa issue linki: Closes #__ -->



## 🚀 Production'da çalışması için gereken değişiklikler
<!--
  Merge sonrası prod'da çalışması için NE gerekiyor?
  Yoksa "Ekstra değişiklik gerekmiyor" yaz.
  Örnekler:
  - [ ] Yeni env değişkeni / secret: ____
  - [ ] Backend deploy / migration: ____
  - [ ] Yeni API endpoint canlıda olmalı: ____
  - [ ] App Store / Play Store build alınmalı
  - [ ] Feature flag / config: ____
-->



## 📱 Bu iş için mobilde hangi branch merge edilmeli?
<!-- Bağımlılık varsa yaz. Yoksa "Sadece bu branch" yaz. -->

- Base branch: `master`
- Bağımlı branch(ler): ____

---

## ✅ Definition of Done (kapatmadan kontrol et)
- [ ] `flutter analyze` temiz (hata yok)
- [ ] `flutter test` yeşil
- [ ] `dart format lib/` uygulandı
- [ ] Yeni kullanıcıya görünen metinler i18n'de var (`app_en.arb` + `app_es.arb` + `app_ca.arb`), `flutter gen-l10n` çalıştırıldı
- [ ] Hardcode yok (base URL / ID / email / şehir-kategori listesi — hepsi API'den)
- [ ] `BACKLOG.md` güncellendi (biten iş çıkarıldı / yeni bug eklendi)

## 🤖 AI ile mi yazıldı?
<!-- Hangi tool + ne yaptırdın? Sorumluluk sende kalır, sorun değil — sadece şeffaf ol. -->

