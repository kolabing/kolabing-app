# Event Challenge QR Gamification — Tasarım (v1)

> Tarih: 2026-08-22 · Durum: **onay bekliyor** (implementasyon başlamadı)
> Öncül denetim: [`docs/reviews/2026-08-22-attendee-qr-review.md`](../reviews/2026-08-22-attendee-qr-review.md)
> Backend sözleşmesi doğrulandı: `docs/ROLES-BACKEND-DB-MAP.md` §11 + §11.1

---

## 1. Hedef akış

```
1) Katılımcı etkinliğe gelir
   → organizatörün EVENT QR'ını tarar
   → POST /checkin { token }
   → app "aktif etkinlik" oturumunu açar (event_id + event_name + bitiş)

2) İki katılımcı eşleşir
   → A, B'nin PROFİL QR'ını tarar  (https://{shareHost}/u/{profileId})
   → GET /events/{aktif_event}/challenges
   → o etkinliğe özel challenge'lar listelenir

3) A bir challenge seçer ve oynarlar
   → POST /challenges/initiate { challenge_id, event_id, verifier_profile_id: B }
   → A'nın ekranında ONAY QR'ı çıkar (https://{shareHost}/qr/verify/{completionId})

4) B onaylar
   → B, A'nın onay QR'ını tarar
   → POST /challenge-completions/{id}/verify
   → backend point_ledger'a XP yazar + attendee_profiles.total_challenges_completed++

5) A'nın ekranı polling ile status=verified görür
   → "+X XP" kutlaması + stats/badge provider invalidate
```

## 2. Alınan kararlar (2026-08-22 brainstorm)

| Karar | Seçim | Sonuç |
|---|---|---|
| Check-in nasıl olur | **Organizatör event QR'ı ile ayrı adım**; peer-scan yalnızca eşleşme | Backend değişmez |
| Kim oynar / kim onaylar | **Tarayan oynar (challenger), taranan onaylar (verifier)**; XP tarayana yazar. B de XP isterse A'yı tarar | Backend'in mevcut modeli birebir |
| Event context | **Yerel "aktif etkinlik" oturumu** (`POST /checkin` cevabından); fallback: "going" olduğu canlı etkinliklerden seçtir | `GET /me/checkins` gerekmez |
| B onayı nasıl görür | **v1: yalnızca onay QR'ı** (yan yana akış). Bekleyen-onaylar listesi + push **v2** | Backend değişmez |

## 3. Backend: sıfır değişiklik — hepsi canlı

| Adım | Endpoint | Notu |
|---|---|---|
| Organizatör QR üret | `POST /events/{event}/generate-qr` | `data.checkin_token`; 403 = yetkisiz |
| Check-in | `POST /checkin {token}` | Çağıranı check-in eder; `total_events_attended++` |
| Etkinlik challenge'ları | `GET /events/{event}/challenges` | `trigger_action IS NULL` olanlar (general mission'lar hariç — §11.1) |
| Challenge başlat | `POST /challenges/initiate {challenge_id, event_id, verifier_profile_id}` | 201 → `ChallengeCompletion`; 422 = ikisi de check-in olmalı; 409 = limit/zaten var |
| Onayla / reddet | `POST /challenge-completions/{id}/verify` \| `/reject` | **`verify()` point_ledger'a yazar** = XP burada düşer |
| Geçmiş / polling | `GET /me/challenge-completions?page&limit` | Status filtresi yok → id ile eşleyip poll et |

Mevcut Dart servisleri (`CheckinService`, `ChallengeService`) bu endpoint'lerin **tamamını** zaten sarıyor. Yazılacak olan şey servis değil, **akış + UI**.

## 4. Tek tarayıcı, üç QR türü

Tek `AttendeeScannerScreen` üç payload'ı ayırt eder:

| # | Tür | Payload | Aksiyon |
|---|---|---|---|
| 1 | Event check-in | Opak token (URL **değil**) | `POST /checkin` → aktif oturumu aç |
| 2 | Peer profil | `https://{host}/u/{profileId}` | Eşleş → challenge listesi |
| 3 | Onay | `https://{host}/qr/verify/{completionId}` | `POST .../verify` |

**Parser kuralı** (`QrPayload.parse`, saf fonksiyon — kolay test edilir):
- `Uri.tryParse` başarılı **ve** path `/u/{id}` → peer
- path `/qr/verify/{id}` → onay
- URL değil / şema yok → check-in token adayı (uzunluk + karakter seti ön kontrolü)
- Hiçbiri → i18n'li "tanınmayan QR" hatası, kameraya geri dön

**Host'a bakılmaz.** `Environment.shareHost` prod'da `kolabing.com`, dev'de `kolabing-v2-development-uhzrzd.laravel.cloud` — host'a bağlamak dev build'de akışı kırar. Path yeterli.

Bugünkü `_isValidCheckinToken` (`data.length >= 10`) bu parser'la değiştirilir — şu an her rastgele QR sunucuya POST ediliyor.

## 5. Dosya planı

**Yeni**
- `gamification/models/qr_payload.dart` — payload union + `parse()`
- `gamification/models/active_event_session.dart` — `{eventId, eventName, startedAt, expiresAt}`
- `gamification/providers/active_event_session_provider.dart` — SharedPreferences ile kalıcı; süre = etkinlik bitişi + 2sa tolerans, yoksa check-in + 12sa
- `gamification/screens/attendee_scanner_screen.dart` — tek tarayıcı; mevcut `qr_scanner_screen.dart` buraya refactor edilir (kamera/overlay kodu korunur)
- `gamification/widgets/peer_challenge_sheet.dart` — peer tarandıktan sonra: "X ile eşleştin" + etkinlik challenge listesi (`eventChallengesProvider`)
- `gamification/screens/challenge_verify_qr_screen.dart` — A'nın onay QR'ı + polling + "+X XP" kutlaması
- `gamification/providers/challenge_completion_poll_provider.dart` — completion id ile 3sn'de bir `GET /me/challenge-completions`, `verified`/`rejected`'ta durur

**Değişen**
- `gamification/screens/attendee_main_screen.dart` — app-bar QR ikonu artık **QR hub** sheet'i açar: **Tara** / **QR'ım** (mevcut `_MyProfileQrSheet` "QR'ım" olarak korunur). Nav 3 sekmede kalır.
- `event/screens/event_hub_screen.dart` — lider: "Check-in QR'ını göster" → `/attendee/events/:id/qr` (bugün erişilemeyen `EventQRCodeScreen`'i canlandırır). Member: "Check-in ol" → tarayıcı.
- `config/feature_flags.dart` — `kGamificationSetupEnabled` akış uçtan uca çalışınca `true`
- `config/routes/routes.dart` — ölü sabitleri temizle: `eventCheckins` (kayıtlı değil, ekran yok), `editChallenge` (ekran yok)
- `l10n/app_{en,es,ca}.arb` — tüm yeni stringler

**Dokunulmuyor (ayrı ticket):** `BadgesScreen`, `RewardWalletScreen`, `SpinWheelScreen`, `StatsScreen`, `LeaderboardScreen` — bu akışta yerleri yok. "Surface or delete" kararı ayrı ticket'a. Bu ticket kapsamını şişirmiyoruz.

## 6. Hata durumları

| Durum | Davranış |
|---|---|
| `/checkin` 404 | "Geçersiz check-in kodu" — kameraya dön |
| `/checkin` 409 (zaten check-in) | **Hata değil**: aktif oturumu yine aç, "Zaten check-in oldun" bilgi tonu |
| `/checkin` 422 | Backend mesajını göster (etkinlik check-in kabul etmiyor) |
| Kendi profil QR'ını tarama | "Kendi QR'ını tarayamazsın" |
| Aktif oturum yok, peer tarandı | "going" olduğu canlı etkinliklerden seçtir; hiç yoksa "Önce check-in ol" + tarayıcıya kısa yol |
| `initiate` 422 | "İkinizin de check-in olması gerekiyor" + check-in kısa yolu |
| `initiate` 409 | Backend mesajı (limit / zaten başlatılmış) |
| Onay QR'ını yanlış kişi tarar | Backend reddeder (caller ≠ verifier) → i18n'li mesaj |
| Polling zaman aşımı (2 dk) | "Onay bekleniyor" durumuna düş, "QR'ı tekrar göster" aksiyonu kalır |

## 7. Riskler / kabul edilen sınırlar

- **Askıda kalan onay (v1'in bilinen açığı):** B taramadan ayrılırsa completion `pending` kalır. Azaltma: A'nın challenge geçmişinde pending kayıt için **"Onay QR'ını tekrar göster"** aksiyonu → sonradan onaylatılabilir. Kalıcı çözüm (bekleyen-onaylar listesi + push) **v2**.
- **Yerel oturum kırılganlığı:** app silinir / cihaz değişirse aktif etkinlik kaybolur → fallback picker + backend'in 422 guard'ı emniyet ağı.
- **Attendee kaydı hâlâ kapalı** (`user_type_selection_screen.dart:235` `isEnabled:false`). Bu akışın gerçek kullanıcıya ulaşması için o gate'in açılması **ayrı bir ürün kararı** — bu ticket teknik olarak hazır hale getirir.
- **XP kime yazılıyor [VERIFY]:** `ChallengeCompletionService::verify()` point_ledger'a yazıyor, ama ledger satırının `profile_id`'si challenger mı doğrulanmalı. İlk uçtan uca testte prod DB'den teyit edilecek; challenger değilse backend follow-up açılır (client-side puan **uydurulmaz**).

## 8. Test planı

- **Unit:** `QrPayload.parse` — 3 tür × (prod host, dev host, bozuk, boş, şemasız token, yanlış path)
- **Unit:** `CheckinService.checkIn` 200/404/409/422; `ChallengeService.initiateChallenge` 201/422/409; `verifyChallenge` 200/403
- **Unit:** `ActiveEventSession` persist + expiry (bitmiş etkinlik oturumu döndürmez)
- **Widget:** peer scan → challenge sheet → initiate → onay QR → (mock verify) → "+X XP"
- **Widget:** aktif oturum yokken peer scan → picker / "önce check-in ol"
- Bugün check-in/QR için **hiç test yok** — bu plan o boşluğu da kapatıyor.

## 9. Kapsam dışı (ayrı ticket'lar)

1. Bekleyen onaylar listesi + push bildirimi (v2)
2. Orphan gamification ekranları: surface-or-delete
3. Yoklama listesi ekranı (`GET /events/{id}/checkins` provider'ı hazır)
4. NF-3 geolock check-in
5. Attendee kaydının açılması (ürün kararı)
6. `EditChallengeScreen` (servis `updateChallenge` hazır)
