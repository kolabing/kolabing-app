# Changelog

## 1.3.0+10 — 2026-05-21

Barcelona launch readiness release. 32 bug reports closed, 5 new features
shipped, full backend contract alignment (2026-05-21 deploy).

### New features

- **Finish Collaboration** — both parties can mark a `scheduled` /
  `inProgress` collaboration as completed via the new
  `POST /collaborations/{id}/complete` endpoint. Closes the loop on
  successful events so dashboard counts and review eligibility work.
- **Send Kolab proposal from Discover** — business viewing a community
  card in Explore can now open the community's public profile and send a
  targeted Kolab. Wired through `GET /communities/{id}/public-profile`,
  routed via `?recipient_community_id=…` query param, and persisted into
  the publish body so backend can scope visibility.
- **Offer headline on the card** — every venue/product Kolab now ships a
  one-line `offer_headline` that pins to the discovery card so community
  leaders can evaluate without opening every listing.
- **Base + negotiable offer model** — the writer can configure a public
  `base_offer` plus a list of `negotiation_triggers` that only unlock for
  communities that have applied. Reader-side gating respected.
- **Match-score breakdown widget** — discovery cards now show the
  contributing signals (category fit, location, audience, past activity)
  as compact mini-bars next to the match %. Backend exposes
  `match_breakdown[]`; the FE renders them in weight × score order.

### Bug fixes (highlights)

- **B7**: KolabMedia type alignment — frontend now sends `'image'` /
  `'video'` (was `'photo'`), unblocking the silent publish failure.
- **B1**: Post-publish status guard surfaces the paywall when the backend
  returns 200 with a still-draft kolab (silent subscription block).
- **C8**: Flexible scheduling now exposes a date-range picker on the
  business side so users can pick a window instead of being silently
  blocked at publish.
- **B3**: Draft list invalidates after save — newly saved drafts appear
  immediately instead of disappearing behind a stale cache.
- **C12**: Accept-date picker is now constrained to the publisher's
  availability mode (one-time → single date, recurring → matching
  weekdays only, flexible → full range).
- **C13**: Removed the contact-methods exchange step on collaboration
  accept; both parties continue in the in-app chat.
- **C1**: Keyboard dismiss on tap-outside across kolab venue/product /
  community detail / logistics screens — bottom action bar is reachable
  again.
- **C7**: New "Use venue photos" button on Kolab media step pulls in
  the business's existing primary-venue photos so users don't re-upload
  the same shots for every Kolab.
- **C10**: Picked image normaliser materialises Google-Photos /
  iCloud-sourced content URIs to a real temp file, so previews render
  reliably on iOS.
- **D3**: "Mark as completed" action added on `CollaborationDetailScreen`,
  visible while the collaboration is `scheduled` / `inProgress`.
- **E5**: Business onboarding step 2 now reads "Add logo" instead of
  "Add photo" (label scoped via new `addLabel` param on
  `PhotoUploadWidget`).
- **B6 / B2 / B4 / B8**: Persistent error banner + auth-aware "Page not
  found" recovery screen + structured `[AUTH]` / `[B2]` / `[B6]` logging
  so QA captures the exact failure on the next test pass.

### Backend contract alignment (2026-05-21)

Frontend now consumes and emits the new contract:
- `media[*].type` constrained to `image` / `video`
- `applications/{id}/accept` tolerates empty `contact_methods`
- `kolabs/{id}/publish` accepts optional `recipient_community_id`
- `collaborations/{id}/complete` live, real HTTP wired
- `communities/{id}/public-profile` live, public profile screen wired
- Venue/product kolabs ship `offer_headline`, `base_offer`,
  optional `negotiation_triggers`
- Discovery responses include `match_score` + ordered `match_breakdown`

Open backend tickets BE-017..BE-019 documented in
`.agent/documentations/backend-tickets-from-bug-list-2026-05-21.md`.

### Verified

- `flutter analyze lib`: 0 errors.
- `flutter test`: 107 passed, 3 pre-existing failures (welcome_screen × 2,
  explore_screen × 1; all confirmed on `master` via `git stash`).
- No regressions introduced.
