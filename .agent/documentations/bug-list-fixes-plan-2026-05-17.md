# Bug List Master Plan — 2026-05-17

Source: Daniel's QA list (Volkan's bug & build list, merged 2026-04-22, 2026-04-28, 2026-05-17).

Total open items: 32 across 8 buckets (B/C/D/E/F/G/H plus carryovers from A).
Target: Barcelona launch.

## Execution Phases

Daniel's "Suggested order of work (2026-05-17)" maps to 7 phases. Each phase = one or more `.agent/todo/` task file. Phases are gated; finish a phase before starting the next.

### Phase 1 — Core funnel unblockers (CRITICAL)
Cannot ship without these. All in `.agent/todo/phase1-*.md`.

| Task file | Bugs covered | Why |
|-----------|--------------|-----|
| `phase1-fix-business-signup-account-creation.md` | B6 | Top-of-funnel: nobody can register as a business. |
| `phase1-fix-publish-paywall-and-image-url.md` | B1, B7 | Cannot publish a Kolab. Wire `SubscriptionPaywall` to publish + fix image URL payload. |
| `phase1-fix-flexible-scheduling-validation.md` | C8 | "Flexible" mode silently blocks publish. |
| `phase1-fix-draft-save-load.md` | B3 | Drafts say saved but disappear. |
| `phase1-fix-auth-session-and-login.md` | B2, B4, B8 | Login broken + fresh-sign-in auth-expired across screens. Likely shared root cause. |

**Estimated effort:** 4–6 days of focused work.

### Phase 2 — Sign-up completability
| Task file | Bugs | Why |
|-----------|------|-----|
| `phase2-fix-create-account-and-onboarding-copy.md` | E3, E2, E5 | Password field, Login/Register chooser, "Add logo" copy. |
| `phase2-fix-venue-address-and-merge-signup.md` | C6, E1 | Full street address + merge venue/business signup. |

### Phase 3 — Publish→accept contract
| Task file | Bugs | Why |
|-----------|------|-----|
| `phase3-fix-community-kolab-and-accept-flow.md` | C11, C12, C13 | Drop venue step for community Kolab, constrain accept-date, drop contact-methods step. |

### Phase 4 — Content-creation friction
| Task file | Bugs | Why |
|-----------|------|-----|
| `phase4-fix-content-upload-and-keyboard.md` | C1, C7, C2, C3, C4, C10, B5, D2 | Keyboard dismiss, photo reuse, media uploads, Google Photos preview, venue type error, Business in Ideal Community. |

### Phase 5 — Discovery & matching transparency
Product decisions gate implementation. Owner: PM + Volkan.
| Task file | Bugs |
|-----------|------|
| `phase5-discovery-and-matching.md` | H3, H4, H1, H2 |

### Phase 6 — Conversion polish
| Task file | Bugs |
|-----------|------|
| `phase6-conversion-polish.md` | D3, C9, C5, F1, D1, E4, H5 |

### Phase 7 — Email infra
| Task file | Bugs |
|-----------|------|
| `phase7-email-banner-upload.md` | G1 |

## Cross-cutting investigation: auth root cause

Findings from initial scan (`grep AuthException`):
- `opportunity_service.dart` throws `AuthException('Session expired. Please sign in again.')` from 10+ call-sites, raw. Same pattern likely in `kolab_service.dart`, `auth_service.dart`, etc.
- The pattern: read token → if missing throw → if 401 retry once → if still 401 throw. The retry uses `allowRetry: false` which short-circuits the refresh logic.
- Likely fix: introduce a centralized HTTP interceptor that (a) reads the current token from `auth_state_provider`, (b) on 401 calls a single refresh, (c) retries the original request once with the new token, (d) only throws AuthException if refresh itself failed. This collapses B2 + B4 + B8 into one fix.
- Investigate why fresh-sign-in tokens "expire": likely `auth_state_provider` is not awaited before screens fire their first request, OR refresh-token rotation is invalidating the just-issued access token.

## What was already addressed (verify, don't re-do)
From `.agent/done/`:
- `redesign-splash-auth-flow.md` — may overlap with E2 (Login/Register chooser)
- `fix-publish-shows-draft-saved-modal.md` — B3 likely came back / is wider than this
- `password-reset-deep-link.md` — separate from B3/E3
- `fix-remove-business-location-step.md` — may overlap with C11

Re-test these against the 2026-05-17 build before re-implementing.

## Decision gates before starting

1. **Phase 1 ordering.** Recommendation: B6 → B1/B7 → B3 → auth (B2/B8) → C8. Reason: B6 blocks new accounts entirely; B1/B7 blocks the publish funnel; B3 enables manual workarounds; auth is the largest investigation and should run in parallel as a background thread.
2. **Subscription paywall integration.** Two paths: (a) wire existing `subscription_paywall.dart` widget as a modal on publish-tap when `user.hasActiveSubscription == false`, or (b) hard-gate via the route. Pick (a) — keeps users in the publish flow context.
3. **Auth root cause vs symptom patches.** Tempting to patch each screen. Don't. Fix the interceptor + token-state-await once.

## Backout & safety

- Keep auth/payment changes behind a feature flag where possible.
- Test on test seed account AND a freshly registered account each phase (the test seed exposes B4-style staleness; fresh accounts expose B6/B8).
- After each phase: run `flutter analyze` + `flutter test` and smoke-test the affected flow on iOS sim.
