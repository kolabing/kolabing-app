# Shareable Opportunity Link Design

**Date:** 2026-05-16  
**Status:** Approved for planning  
**Ticket:** TICKET 2, Shareable Collaboration Link (Deep Link)

## Goal

Give every published community opportunity a public, polished share URL that:

- opens the installed app directly on the opportunity detail screen
- shows a mobile web preview when the app is not installed
- preserves the destination through install so the first app open lands on the same opportunity
- lets a business continue into the existing apply flow with minimal friction

## Scope

This ticket targets the **published opportunity detail that a business can apply to**, not the post-acceptance `Collaboration` object.

In the current app, the public/apply-able object is the `Opportunity` flow:

- opportunity creation and publish live under `lib/features/opportunity/` and `lib/features/community/screens/create_opportunity_screen.dart`
- the apply screen is `CommunityOfferDetailScreen`
- application submission posts to `/opportunities/{id}/applications`

The `Collaboration` feature is the accepted, post-match state and is out of scope for this ticket.

## Current State

### What already exists

- The app already has a detail screen that matches the share target: `CommunityOfferDetailScreen`.
- The app already has an existing apply flow via `ApplyModal`.
- The router already supports shared detail-style routes and custom-scheme deep linking for password reset.
- `kolabing.com` is already the production API/app domain used by the mobile client.
- `share_plus` is already in use elsewhere in the app.

### What is missing

- No public canonical URL exists for an individual published opportunity.
- No verified `https` universal link / Android App Link setup exists.
- No listener currently routes incoming `https` links into the app.
- No deferred deep link solution exists for first-open after install.
- No web preview page with Open Graph metadata exists.
- No post-publish share entry point exists on the opportunity flow.

### Important repo finding

`MyOpportunitiesScreen` is currently wired to `myKolabsProvider` rather than the `Opportunity` provider stack. This ticket should use the `Opportunity` model and detail/apply flow as the source of truth. If the community management screen needs a share button immediately, that screen may need a targeted cleanup as part of implementation.

## Requirements

### Functional

1. Every published opportunity gets a canonical public URL: `https://kolabing.com/c/<opportunity_id>`.
2. Sharing from the app produces that URL and a polished preview in social apps.
3. If the app is installed, the URL opens the app on that opportunity detail screen.
4. If the app is not installed, the URL opens a lightweight mobile web preview with install CTA.
5. After install, first app open lands on the same opportunity.
6. If the user is not authenticated when they try to apply, the app must preserve the destination and return them to the same opportunity after auth/onboarding.

### Non-functional

- Open Graph metadata is mandatory.
- The web preview must feel branded and intentional, not a raw JSON dump or generic app-install page.
- The link contract must be stable even if the internal mobile route structure changes later.

## Decision Summary

### Recommended architecture

Use a **hybrid canonical URL + Branch deferred deep linking** setup:

- canonical public URL on `kolabing.com`: `https://kolabing.com/c/<id>`
- iOS Universal Links + Android App Links for installed-app opens
- Branch for deferred deep linking across install, especially for iOS
- branded `kolabing.com` web preview for users without the app

### Why this architecture

- A real `kolabing.com` URL is required for polished previews and long-term SEO/shareability.
- Native universal links/App Links are the right installed-app transport.
- Native universal links alone do not reliably satisfy deferred deep linking through App Store install on iOS.
- Firebase Dynamic Links is not acceptable for a new implementation because Google deprecated it and shut it down on **August 25, 2025**.

## Canonical URL Contract

### Public URL

`https://kolabing.com/c/<opportunity_id>`

Optional future-friendly query params may be appended for attribution, but the canonical content identity is the path segment:

- `utm_source`
- `utm_medium`
- `utm_campaign`
- Branch-specific attribution params

The app must ignore unknown marketing params and route by the opportunity ID in the path.

### In-app destination

The app should resolve `/c/:id` to the existing public opportunity detail screen backed by `OpportunityService.getOpportunity(id)`.

The mobile route exposed to the router can be either:

- a new shared route `/c/:id`, or
- an internal redirect from `/c/:id` to the existing detail screen builder

The public share contract must stay `https://kolabing.com/c/<id>` regardless of internal route naming.

## User Flow

### 1. Community publishes an opportunity

On successful publish:

- show success UI that includes a primary `Share` action
- generate/share the canonical URL
- allow repeated sharing later from the published opportunity management UI

### 2. Recipient has app installed

- taps `https://kolabing.com/c/<id>`
- OS resolves universal link / App Link to Kolabing
- app opens directly on the opportunity detail screen
- user can tap `Apply now`

### 3. Recipient does not have app installed

- taps `https://kolabing.com/c/<id>`
- lands on a mobile web preview page
- sees headline, cover image, community snippet, key terms, and a strong install CTA
- install CTA routes through Branch so destination survives install
- first open lands on the same opportunity in-app

### 4. Recipient reaches app but is not authenticated

When the user taps `Apply now` without a valid authenticated business session:

- the app stores a pending destination pointing to the same opportunity
- auth / signup / onboarding runs normally
- once the user reaches an eligible post-auth state, the app returns them to the opportunity detail
- if the original intent included `apply=1`, reopen the apply sheet automatically

This avoids dropping the user on a generic dashboard after signup.

## Web Preview Design

### Preview content

The page should include:

- opportunity title
- cover image
- community logo/avatar
- community display name
- city / venue mode
- high-signal business offer summary
- high-signal deliverables summary
- availability summary
- install CTA

The page should not expose private application/chat data.

### Open Graph metadata

Each opportunity page must provide:

- `og:title`
- `og:description`
- `og:image`
- `og:url`
- `og:type`
- Twitter card tags

### OG image rules

Preferred:

- generated image per opportunity using cover image, community branding, and headline

Fallback:

- cover photo with Kolabing branding overlay and truncated headline

The fallback must still look polished in WhatsApp, Instagram DM, iMessage, Slack, and email previews.

## Backend / Web Requirements

This mobile repo cannot deliver the public web preview or OG rendering by itself. The following companion work is required on the website/backend side:

### Required capabilities

1. Serve `https://kolabing.com/c/<id>` as a public page.
2. Resolve only **published** opportunities on that page.
3. Return `404` or a closed-state page for invalid, draft, removed, or unauthorized opportunities.
4. Render OG metadata server-side so crawlers can read it.
5. Provide install CTAs for iOS and Android.
6. Integrate the same content identity with Branch link data for deferred deep linking.

### Data contract for preview

The web layer needs a public share payload containing:

- `id`
- `title`
- `short_description`
- `cover_image_url`
- `community_name`
- `community_avatar_url`
- `preferred_city`
- `venue_mode`
- `availability_summary`
- `offer_summary`
- `deliverables_summary`
- `status`

This can come from:

- a public website render endpoint, or
- an existing public opportunity endpoint plus a server-rendered web page

If the current `/api/v1/opportunities/{id}` contract is not safe for anonymous web use, add a dedicated public serializer rather than stretching the authenticated mobile payload.

## Mobile App Changes

### 1. Route support

Add a shared app route for public opportunity links:

- `/c/:id`

This route should build the same `CommunityOfferDetailScreen` experience used today for applying.

### 2. Incoming link handling

Add explicit incoming `https` link handling so the app can respond to:

- cold start
- warm start
- resumed app

Do not rely on a transitive dependency for this. If `app_links` is used, declare it directly in `pubspec.yaml` and wrap it in a small routing service owned by the app.

### 3. Share action

Add share entry points in the opportunity publishing flow:

- publish success dialog in `CreateOpportunityScreen`
- published opportunity management UI

The shared text should be short and channel-safe. Example:

`Check out this collaboration opportunity on Kolabing: https://kolabing.com/c/<id>`

### 4. Apply gating

Before opening `ApplyModal`, detect whether the current user can apply.

If not authenticated, or if auth state is not eligible yet:

- store pending destination `/c/<id>?apply=1`
- route into login / signup
- after auth and any required permissions/onboarding, resume the pending destination

If the user is already signed in with a non-business account type, the app must not open `ApplyModal`. Instead, it should show a clear business-only gate and route them into the correct account-selection or business-auth path while preserving the same destination.

### 5. Resume after auth

The app already uses `destination=` query params for permission routing. Extend this pattern into a small destination-resume mechanism shared by:

- splash restore
- login success
- signup success
- onboarding completion
- permission screen completion

This prevents deep-linked users from being dropped on the dashboard.

## Branch Integration

### Branch responsibilities

Branch should carry:

- canonical identifier: opportunity ID
- canonical URL: `https://kolabing.com/c/<id>`
- desktop/mobile web fallback URL
- install routing data
- attribution metadata when available

### Minimal Branch payload

- `entity_type=opportunity`
- `entity_id=<id>`
- `canonical_url=https://kolabing.com/c/<id>`
- `open_apply=true` when applicable

### Why Branch is still needed

iOS deferred deep linking through App Store install is the weak point of a self-hosted-only setup. Branch closes that gap while still allowing Kolabing to keep a branded canonical URL and branded web preview.

## Platform Configuration

### iOS

Add Associated Domains entitlement for the share host, likely:

- `applinks:kolabing.com`
- `applinks:www.kolabing.com` only if that host will also be used

Serve an `apple-app-site-association` file for each declared host and include the `/c/*` path.

### Android

Add verified App Link intent filters for:

- scheme `https`
- host `kolabing.com`
- path prefix `/c/`

Set `android:autoVerify="true"` and publish `/.well-known/assetlinks.json` with the release signing fingerprint used by Play App Signing.

### Existing custom scheme

Keep `kolabing://` support for existing flows such as password reset. This ticket adds verified `https` handling; it does not replace all custom-scheme usage.

## Analytics

Track at minimum:

- opportunity share initiated
- opportunity share completed
- shared link opened in web
- shared link opened in app
- install CTA tapped
- deferred deep link resolved
- apply started from shared link
- application submitted from shared link

Include opportunity ID and source channel when available.

## Security and Content Rules

- Only `published` opportunities may be public.
- Draft and private opportunities must never return a share page.
- The app and web layers must validate the incoming ID and ignore malformed URLs.
- The public page must expose only share-safe fields, not internal application counts unless explicitly desired.

## Rollout Strategy

### Phase 1

- mobile `/c/:id` route
- verified universal links / App Links
- share action in app
- web preview page with OG metadata

### Phase 2

- Branch deferred deep linking
- pending destination resume with auto-open apply modal when the incoming destination includes `apply=1`
- analytics hardening

The ticket is not fully complete until Phase 2 is live, because acceptance criterion 4 depends on deferred deep linking after install.

## Risks

1. **Current source-of-truth split between `Kolab` and `Opportunity`.**  
   The feature must be anchored on `Opportunity`, because that is the current public apply path.

2. **iOS deferred deep linking without Branch is unreliable.**  
   Shipping only universal links would leave criterion 4 partially unmet.

3. **Crawler previews depend on server-rendered metadata.**  
   If `kolabing.com/c/<id>` is a client-only page, WhatsApp and Instagram previews will be poor or absent.

4. **Post-auth continuation can feel broken if destination state is not centralized.**  
   This is not just a routing task; it is an auth-resume task.

## Success Criteria Mapping

1. Public URL for every published opportunity  
   Covered by canonical `https://kolabing.com/c/<id>`.

2. Share action produces paste-ready URL with clean preview  
   Covered by in-app share entry points plus OG-rendered web page.

3. Installed app opens directly on collaboration detail  
   Interpreted for this ticket as installed app opens the **published opportunity detail** and is covered by `/c/:id` + universal links/App Links.

4. No-app users get web preview and, after install, land on same opportunity  
   Covered by mobile preview page + Branch deferred deep linking.

5. Works on iOS and Android  
   Covered by Associated Domains, AASA, Android App Links, and Branch install routing.

## Final Recommendation

Implement this feature against the `Opportunity` stack with a branded canonical URL on `kolabing.com`, verified native deep links for installed users, and Branch for deferred deep linking across install. Treat the web preview and the app resume flow as first-class parts of the feature, not optional polish.
