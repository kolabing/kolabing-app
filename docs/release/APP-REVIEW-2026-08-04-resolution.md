# App Review resolution — Kolabing 1.5 (build 33), rejected 2026-08-04

**Submission ID:** `18720871-a906-4023-8ac0-c0054e1818f1`
**Version reviewed:** 1.5 (33) · **Review date:** 2026-08-04 · **Device:** iPhone 17 Pro Max, iOS 26.5

Apple flagged **two** guideline issues. **Neither is an app-code bug** — both are
App Store Connect / account-level fixes (Account Holder / Admin). This doc pins each
to the exact action, plus the corrected App Privacy label spec. The €49.99 pricing change
ships alongside this doc (all user-visible `€39.99` strings → `€49.99`).

> **2026-08-07 correction:** the first pass wrote **€49**; the price actually chosen is
> **€49.99** (the standard EUR price point). Every user-visible string and the ASC tier
> below now read €49.99.

---

## Issue 1 — Guideline 5.1.2(i): Privacy / App Tracking Transparency

**What Apple said:** the App Privacy information in ASC declares the app collects data
**used to track** the user — *Other Contact Info, Precise Location, Emails or Text
Messages, Photos or Videos, Purchase History, Coarse Location, Advertising Data,
Browsing History, Phone Number, Other Diagnostic Data, Device ID* — but the app never
requests permission through the AppTrackingTransparency (ATT) framework.

**Ground truth (from the code, not memory).** The app's only data-touching SDKs are:

| SDK | What it does | Is it "tracking" (Apple's definition)? |
|-----|--------------|----------------------------------------|
| `firebase_messaging` / `firebase_core` | Push delivery | No |
| `firebase_crashlytics` | Crash diagnostics | No |
| `onesignal_flutter` | Push + in-app messaging | No |
| `posthog_flutter` | First-party product analytics — curated, **no autocapture, no ads**, identify by our own user id | No |
| `in_app_purchase` / `in_app_purchase_storekit` | Subscriptions | No |

There is **no ad SDK, no IDFA, no AppsFlyer/Adjust/Facebook SDK, no
`requestTrackingAuthorization` call, and no `NSUserTrackingUsageDescription`** anywhere
in the app. Apple defines *tracking* as linking data with **third-party** data for
advertising, or sharing it with a **data broker** — the app does **neither**. So the
app genuinely **does not track**.

**→ Correct fix (ASC metadata — Account Holder/Admin; NOT a code change).**
Correct the App Privacy labels so **nothing** sits under *"Used to Track You,"* and
remove the data types the app does not actually collect. Do **not** add an ATT prompt —
Apple discourages showing one when the app doesn't track, and adding it would contradict
the corrected labels.

### Corrected App Privacy label spec (transcribe into ASC → App Privacy)

**"Used to Track You": NONE.** (Move everything out of this bucket.)

**Data Linked to You** — purpose = *App Functionality* (and *Analytics* where noted):
- **Email Address / Name** — from Google/Apple sign-in · App Functionality (account)
- **User ID** — our account id · App Functionality + Analytics (PostHog, first-party)
- **Photos** — user-uploaded profile/community images · App Functionality (user content)
- **Purchase History** — subscription status · App Functionality
- **Product Interaction / Usage Data** — PostHog events · Analytics
- **Coarse Location** — *only* the city derived from a user-picked venue (Google Places);
  App Functionality. **Do not declare Precise Location** unless the app reads device GPS
  (it does not, per the deps reviewed).

**Data Not Linked to You** — purpose = *App Functionality*:
- **Device ID** — push token (FCM / OneSignal) · App Functionality
- **Crash Data / Other Diagnostic Data** — Crashlytics · App Functionality

**Remove entirely (over-declared, not collected):** *Emails or Text Messages*
(the app does not read messages), *Browsing History* (no web-browsing tracking),
*Advertising Data* (no ads), *Other Contact Info* (contacts not accessed),
*Phone Number* (not collected — Google/Apple sign-in does not provide it and the app
does not ask).

> ⚠️ Confirm before saving: (a) the app does not read device GPS (only user-entered
> venue/city); (b) whether any of Photos/Coarse Location should be *Not Linked* instead
> of *Linked*. If Daniel prefers to **keep** tracking labels for a future ad strategy,
> the app must first implement ATT (`AppTrackingTransparency` + `NSUserTrackingUsageDescription`)
> — that is a separate code change and is **not** recommended now.

---

## Issue 2 — Guideline 2.1(b): In-App Purchase products exhibited bugs

**What Apple said:** the IAP products showed one or more bugs (poor UX) in the sandbox,
and Apple explicitly points to the **Paid Applications Agreement**. The three
subscriptions (*Monthly*, *3 months*, group *Kolabing Premium*) show status **"Rejected"**
— that is a **cascade** from the app rejection and clears on resubmit; it is not an
independent action.

**Ground truth (from the code).** `lib/features/subscription/services/iap_service.dart`
handles the StoreKit flow correctly: it queries product details, handles `error` /
`notFoundIDs`, and every purchase state (`pending` / `purchased` / `restored` / `error` /
`canceled`) with backend verification and graceful fallbacks. When products fail to load
the paywall shows an "unavailable" state — which is **exactly what a reviewer sees when
the products aren't purchasable** for an account/config reason. **No client bug found.**

**→ Fix (ASC / account — in order of likelihood):**
1. **Paid Applications Agreement.** ASC → **Business → Agreements** → sign / renew the
   Paid Applications Agreement so it is **"In Effect,"** and complete **Bank + Tax**
   (payout) details — the agreement stays *Pending* without them, and pending = IAPs
   don't function in sandbox. *(Apple named this directly.)*
2. **Subscription product config.** For **Monthly**, **3 months**, and the **Kolabing
   Premium** group, ensure each has: a localized **display name + description**, a
   **price** (set **Monthly to the €49.99 tier** now — see below), and a **review
   screenshot**; set state to **"Ready to Submit"** and attach to the 1.5 version.
3. **Product IDs must match exactly** (confirmed from code):
   - Monthly → `com.kolabing.kolabingApp.subscription.monthly`
   - 3 months → `com.kolabing.kolabingApp.subscription.three_months`
   - (The app also queries a legacy `com.kolabing.app.subscription.monthly` as a
     fallback, but the **bundle-scoped** id above must be the live one.)
4. **Test in sandbox** with a Sandbox Apple ID and confirm the monthly purchase
   completes before resubmitting.

---

## Pricing → €49.99/month

- Code: every user-visible `€39.99` / `39.99 EUR` string updated to **€49.99** (paywall
  Android fallback, subscribe button, status screen; en/es/ca). On iOS the paywall shows
  **Apple's live price**, so the real number comes from ASC.
- **The actual charged price is the ASC subscription tier.** Set the
  `com.kolabing.kolabingApp.subscription.monthly` product to the **€49.99 tier** in ASC
  (Account Holder). The **3-month** tier price is **not yet defined** by Daniel — left
  unchanged; confirm it before offering the 3-month plan.
- Backend reference config aligned in kolabing-v2 (`config/subscriptions.php`, PR #121).

---

## Daniel's resubmission checklist (App Store Connect, Account Holder)

1. **Business → Agreements:** Paid Applications Agreement **In Effect** + Bank/Tax complete.
2. **App Privacy:** apply the corrected label spec above — **nothing under "Used to Track You,"** remove over-declared types.
3. **Subscriptions:** set **Monthly → €49.99 tier** (Subscriptions → Kolabing Premium → Monthly → **Subscription Prices → +** → Euro-zone base price **49,99 €** → pick the start date → Confirm; existing subscribers need the separate **"Preserve prices for existing subscribers"** choice); ensure Monthly + 3-months + group each have name/description/price/review-screenshot; **Ready to Submit**.
4. **Build:** upload the new build (with the €49.99 strings). Binaries build on Mac/CI — see `PUBLISH-1.5.0.md`.
5. **Resubmit.** In **Review Notes** state: *"The app does not track users; App Privacy labels have been corrected accordingly (no ATT required). IAP: Paid Applications Agreement is in effect; monthly subscription is €49.99."*
6. **Reply in Resolution Center** referencing submission `18720871-a906-4023-8ac0-c0054e1818f1`.

_Prepared by Clark, 2026-08-05._
