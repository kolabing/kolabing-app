# Attendee (Community Member) ekranları + QR check-in sistemi — durum raporu

> Tarih: 2026-08-22 · Branch: `fix/notification-toggles-reflect-consent` (kod okuması `master` @ `63403a4` üzerinden)
> Kapsam: `lib/features/gamification/**`, attendee nav/profil, QR üretme + tarama + `/checkin`, challenge döngüsü.
> Yöntem: kod okuması (dokümana değil koda bakıldı — CLAUDE.md "code wins" kuralı).

---

## 1. Bugün sevkiyattaki gerçek durum

| Konu | Durum | Kanıt |
|---|---|---|
| Attendee **kayıt** | **KAPALI** — kart `isEnabled: false` + "COMING SOON" badge, tap yutuluyor | `auth/screens/user_type_selection_screen.dart:235`, `auth/widgets/selection_card.dart:42` |
| Mevcut attendee hesapları | login olup `/attendee`'ye gidiyor (dashboard çalışıyor) | `routes.dart:960` |
| Attendee bottom nav | **3 sekme**: Home · Communities · Chats. Scan sekmesi kaldırılmış, Profile app-bar avatarında | `gamification/screens/attendee_main_screen.dart:70-118` |
| App-bar QR butonu | Kendi **profil QR**'ını gösteriyor — payload `https://{shareHost}/u/{profileId}`. Check-in token **değil** | `attendee_main_screen.dart:140-146` |
| Attendee profilindeki tek gamification girişi | Points stat → `/rewards` (`PersonalRewardsScreen`) | `attendee_profile_screen.dart:226-230` |
| Gamification setup + Scan Check-Ins | **Feature flag ile kapalı** | `config/feature_flags.dart:12` (`kGamificationSetupEnabled = false`), `event/screens/event_hub_screen.dart:304`, `collaboration/screens/collaboration_detail_screen.dart:269` |

Not: attendee tipinin kapatılması kaza değil — `820e3b7 feat(auth,gamification): gate attendee type + hide in-app gamification (#60)` master'da. Yani FX-14 ("attendee sign-up unreachable → Fixed") **bilinçli olarak geri alınmış**; BACKLOG bunu yansıtmıyor.

---

## 2. QR / check-in sistemi — uçtan uca kırık

Tasarlanan sözleşme (`gamification/services/checkin_service.dart`):
1. Organizatör → `POST /events/{id}/generate-qr` → `data.checkin_token`
2. Attendee token'ı tarar → `POST /checkin {"token": ...}` (**çağıranın** Bearer'ı ile kaydedilir)
3. Organizatör → `GET /events/{id}/checkins` (yoklama listesi)

Kırık noktalar:

1. **Organizatör QR'ı hiç gösteremiyor.** `EventQRCodeScreen` route'u kayıtlı (`/attendee/events/:eventId/qr`, `routes.dart:319,967`) ama **hiçbir ekran bu route'a push etmiyor**. `qrTokenProvider`'ın tek tüketicisi bu erişilemez ekran. → adım 1 hiç çalışmıyor.
2. **Tarayıcının tek girişi kapalı.** `QRScannerScreen` sadece `event/screens/event_hub_screen.dart:126` (`_scanCheckIns()`) üzerinden açılıyor, o da `kGamificationSetupEnabled` (=false) arkasında → üretimde görünmüyor.
3. **Yön ters kurulmuş.** Scanner lider tarafına konmuş (`event_hub_screen.dart:115` yorumu: "Leader: scan attendee check-in QR codes"), ama `POST /checkin` çağıranın token'ıyla kayıt açıyor → **lider tararsa check-in liderin adına yazılır**, attendee'ye değil. Attendee'nin gösterdiği QR da profil URL'i olduğu için pratikte `/checkin` 404 "Invalid check-in token" döner.
4. **Format aslında uyumlu** — `EventQRCodeScreen` ham token'ı encode ediyor (`data: token`, `event_qr_code_screen.dart:231`) ve scanner ham stringi `POST /checkin`'e yolluyor. (Eski task notundaki `{"type":"kolabing_checkin","token":...}` JSON formatı kodda **yok**; koddaki hâli tutarlı.) Sorun format değil, **kimin gösterip kimin taradığı + erişilebilirlik**.
5. **Yoklama listesi ekranı yok.** `eventCheckins` route sabiti tanımlı (`routes.dart:322`) ama GoRoute olarak **kayıtlı değil** ve karşılık gelen ekran yok; `eventCheckinsProvider` hiç tüketilmiyor.
6. **`editChallenge` sabiti ölü** (`routes.dart:333`) — `EditChallengeScreen` hiç yazılmamış, route kayıtlı değil, ama `challenge_service.updateChallenge` (`:138`) mevcut.
7. **Scanner doğrulaması zayıf:** `_isValidCheckinToken` sadece `data.length >= 10` (`qr_scanner_screen.dart:66-70`) → rastgele her QR sunucuya POST ediliyor. Event/etkinlik doğrulaması, süre kontrolü, geofence yok (NF-3 geolock ayrı backlog maddesi).
8. **Check-in/QR için hiç test yok.** `test/features/gamification/` altında yalnızca `discovery_provider_test.dart` + `stats_provider_test.dart` var.
9. İzinler tarafı **tamam**: `ios/Runner/Info.plist:56` `NSCameraUsageDescription`, `AndroidManifest.xml:4` `CAMERA`, `mobile_scanner: ^7.2.0` + `qr_flutter: ^4.1.0` (`pubspec.yaml:80-81`).

---

## 3. Peer-to-peer challenge döngüsü yarım kalmış

- **Var:** `challenge_service.getEventChallenges/createChallenge/updateChallenge/deleteChallenge/initiateChallenge/verifyChallenge/rejectChallenge/getMyChallengeCompletions` + `challenge_provider` sarmalayıcıları.
- **Yok:** `PendingVerificationsScreen` ve `MyChallengeCompletionsScreen` hiç yazılmamış (planda #18/#19 — `.agent/task/inprogress/gamification-phase1.md`). `myChallengeCompletionsProvider` hiçbir yerde tüketilmiyor.
- **Sonuç:** bir challenge başlatılsa bile **doğrulanamaz** → puan hiç yazılmaz. Döngü tanım olarak kapanmıyor.
- Ayrıca `EventChallengesScreen` / `CreateChallengeScreen` / `InitiateChallengeScreen` route'ları kayıtlı ama **hiçbir ekrandan giriş yok**.

---

## 4. Orphan (ölü) gamification yüzeyleri

**Hiçbir nav ulaşmıyor — sadece kendi tanımlarından referanslı:**
`BadgesScreen`, `RewardWalletScreen`, `SpinWheelScreen`, `StatsScreen`, `LeaderboardScreen`.

> BACKLOG NF-21 "LeaderboardScreen community detail'den erişilebilir" diyor — **artık doğru değil**: `lib/features/community`, `lib/features/event`, `lib/features/profile` altında tek bir `Leaderboard` referansı yok.

**Route'u olan, girişi olmayan:** `EventQRCodeScreen`, `EventChallengesScreen`, `CreateChallengeScreen`, `InitiateChallengeScreen`.
**Hiç route'lanmamış:** `EventDiscoveryScreen` (`geolocator`'ın tek çağıranı — `feature_flags.dart:22` notu bunu doğruluyor; bu yüzden konum izni de kapalı).

**Tüketilmeyen provider'lar:** `myChallengeCompletionsProvider`, `eventLeaderboardProvider`, `eventRewardsProvider`, `eventCheckinsProvider`, `confirmRedeemProvider`, `myRewardsPaginatedProvider`.

**Canlı olanlar:** `meRewardsOverviewProvider` (`PersonalRewardsScreen`), `gameCardProvider` (`profile/screens/public_profile_screen.dart`), `discoveryProvider` (attendee home'daki şehir bazlı event feed'i).

---

## 5. İki paralel gamification sistemi var — karar gerekiyor

| | (a) Eski: `lib/features/gamification/` | (b) Yeni: `lib/features/missions/` + community rewards |
|---|---|---|
| Kapsam | event-scoped: challenges, QR check-in, badges, spin wheel, leaderboard, stats | `GET /me/missions` + community_detail **Rewards** tab (`community_rewards_providers`) |
| Durum | çoğu ölü/flag'li | canlı |
| Erişim | attendee profilinden yalnızca `/rewards` | `/missions` **sadece** business + community leader profilinden (`business_profile_screen.dart:1069`, `community_profile_screen.dart:1032`) |

NF-21 ticket'ı (a)'yı canlandırma planı, ama repo (b)'ye kaydı. **Attendee profilinde Missions girişi yok.** İnşaata başlamadan önce "attendee (a)'yı mı canlandırıyor, (b)'ye mi bağlanıyor" kararı verilmeli — yoksa iki XP/puan kaynağı birbiriyle çelişir (FX-8'in aynısı).

---

## 6. BACKLOG ile gerçek durum farkı (senkronlanmalı)

- **NF-21** "NOT started — screens exist, orphaned" yazıyor; oysa `1072014 feat(rewards): P3 — Personal Rewards Screen + leaderboard/profile entries` master'da. Gerçek: NF-21 madde 1'in *küçük bir dilimi* (rewards ekranı + profil girişi) shipped; hub, Rewards tab'ı, home missions preview, earn-loop confirmation **yok**.
- **NF-21 "The gap"** bölümündeki "nav = Home·Communities·Chats·**Scan**" artık yanlış — Scan nav'dan çıkmış.
- **FX-14** "Fixed" görünüyor, ama attendee kaydı `820e3b7` ile bilerek yeniden kapatılmış.
- **FX-21 / FX-22** (attendee home radius kontrolleri + stat ikonları) `42ac9cf` sonrası büyük ölçüde geçersiz: home artık şehir bazlı event feed + chip'ler; Points/Challenges/Events stat kartları home'dan tamamen kalkmış.
- `.agent/task/inprogress/gamification-phase1.md` **hâlâ inprogress**'te ve check-in/challenge kutuları işaretsiz — ya done'a taşınmalı ya da gerçek durumla güncellenmeli (aynı anda tek task kuralı ihlali).

---

## 7. Eksikler — öneri sırası

**Ön koşul (karar):** attendee tipi ne zaman açılacak, ve gamification (a) mı (b) mi? Bu ikisi netleşmeden aşağıdakiler boşa gider.

**P0 — QR döngüsünü doğru kurmak (attendee açılacaksa)**
1. Organizatör QR ekranına giriş: event hub'a (lider görünümü) "Show check-in QR" → `/attendee/events/:id/qr`.
2. Scanner'ı **attendee** tarafına taşı (nav'a Scan aksiyonu ya da event hub'da member görünümü) — `POST /checkin` çağıranı check-in ettiği için tarayan taraf attendee olmak zorunda.
3. Lider "attendee'yi tara" akışı isteniyorsa **backend'de yeni endpoint** gerekir (`POST /events/{id}/checkins {profile_id}`) — bugünkü `/checkin` bunu desteklemiyor. Karar verilmeli: attendee tarar (mevcut) ya da yeni endpoint.
4. `kGamificationSetupEnabled` flag'ini akış tamamlanınca aç; açmadan önce 1-3 bitmiş olmalı.
5. Yoklama listesi: `eventCheckins` route'unu kaydet + ekranı yaz (`eventCheckinsProvider` hazır).
6. Scanner doğrulamasını sıkılaştır (token şekli/uzunluk beklentisi, tekrar tarama debounce'u, hatanın kullanıcıya i18n'li dönmesi).

**P1 — Earn-loop kapanışı**
7. `PendingVerificationsScreen` + `MyChallengeCompletionsScreen` (verify/reject servis+provider hazır).
8. Check-in ve challenge verify sonrası "+X puan" onayı + `stats_provider`/`badge_provider` invalidate (NF-21 madde 3).
9. `EventChallengesScreen`'e giriş (event hub'dan) veya (b)'ye taşınma kararı.

**P2 — Görünürlük**
10. NF-21 madde 1'in geri kalanı: Rewards/Missions hub'ı (Badges + Wallet + Spin + Leaderboard içerikleri) — ya da bu 5 orphan ekranı **sil** ve (b) üzerinden yeniden kur. Bugünkü hâli net teknik borç.
11. Attendee profiline Missions girişi (bugün yalnızca business/leader'da var).
12. `EditChallengeScreen` ya yazılmalı ya `editChallenge` sabiti silinmeli.

**P3 — Hijyen**
13. Check-in/QR için test yok — en azından `CheckinService` (200/404/409/422) ve scanner→provider akışı.
14. BACKLOG'da NF-21 / FX-14 / FX-21 / FX-22 satırlarını gerçek durumla senkronla; `.agent/task/inprogress/gamification-phase1.md`'yi kapat.
15. Route sabitleri denetimi: kayıtlı olmayan sabitler (`eventCheckins`, `editChallenge`) → kaydet ya da sil.
