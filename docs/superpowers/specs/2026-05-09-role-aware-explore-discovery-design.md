# Role-Aware Explore Discovery Design

**Date:** 2026-05-09

## Goal

Increase `apply / match rate` in Explore by replacing generic search-first filtering with:

- opposite-side-only discovery
- `Recommended` ranking by fit
- short role-aware quick filters
- a deeper but still compact filter sheet

## Current State

The mobile app currently uses:

- [ExploreScreen](/Users/volkanoluc/Projects/kolabing-app/lib/features/business/screens/explore_screen.dart:23)
- [OpportunityFilters](/Users/volkanoluc/Projects/kolabing-app/lib/features/opportunity/models/opportunity_filter.dart:5)
- [ExploreFilterSheet](/Users/volkanoluc/Projects/kolabing-app/lib/widgets/explore_filter_sheet.dart:15)

Current limitations:

- explore is built around the old `Opportunity` response shape
- filters are generic: `search`, `category`, `city`, `venue`, `availability`
- community explore is locked to `business`, but business explore is not locked to `community`
- new `kolab` creation data is not used in discovery
- there is no fit ranking, fit reason, or role-aware filter grouping

## Product Decision

This feature is optimized for `higher apply / match rate`, not maximum filter breadth.

That means:

- default feed is `Recommended`
- discovery should show only the opposite side
- manual filters should be short and high-signal
- search becomes secondary, not the main discovery tool

## Discovery Model

### Community viewer

Community users should only see published business offers.

Business offers come from published kolabs with:

- `intent_type = venue_promotion`
- `intent_type = product_promotion`

### Business viewer

Business users should only see published community requests.

Community requests come from published kolabs with:

- `intent_type = community_seeking`

## UI Structure

The existing visual language should stay intact:

- top filter pill stays
- swipe cards stay
- bottom-sheet filter pattern stays

New structure:

1. `Recommended | All` segmented control under the top bar
2. horizontal quick chips under the segmented control
3. existing filter sheet becomes role-aware
4. swipe cards show a small fit badge and 1-2 short fit reasons in `Recommended`

## Quick Filters

### Business -> Community requests

Always-visible quick filters:

- `City`
- `Need`
- `Community Type`
- `Audience Size`

### Community -> Business offers

Always-visible quick filters:

- `City`
- `Collab Type`
- `What They Offer`
- `Availability`

Note:

- `size fit` is not a reliable v1 quick filter for community viewers because the current community profile does not store a viewer audience size. Backend should still return `min_community_size`, but it should be shown as a requirement badge or secondary filter until profile-level audience size exists.

## Filter Sheet

### Business viewer

Primary fields:

- `Community Type`
- `Need`
- `Audience Size`
- `City`
- `Availability`

Secondary fields:

- `Offers In Return`
- `Venue Preference`

### Community viewer

Primary fields:

- `Collab Type`
- `What They Offer`
- `City`
- `Availability`

Secondary fields:

- `Venue Type`
- `Product Type`
- `Expected Deliverables`
- `Minimum Community Size Requirement`

## Fit Ranking

The recommended feed should combine hard gates and soft scoring.

### Hard gates

- authenticated viewer only
- published kolabs only
- opposite-side only
- active availability window only
- viewer must not see own items

### Soft score inputs

For business viewers:

- city match
- business type vs community type affinity
- community needs vs business offerings overlap
- audience size fit
- venue preference compatibility
- availability fit
- freshness

For community viewers:

- city match
- community type vs `seeking_communities` affinity
- business offering overlap
- expected deliverables fit
- intent type preference
- availability fit
- freshness

### Fit reasons

Backend should return short machine-readable reasons that the mobile app can map to UI text.

Examples:

- `city_match`
- `need_offer_overlap`
- `community_type_match`
- `audience_size_match`
- `venue_preference_match`
- `expected_deliverable_match`
- `fresh_listing`

## Data Model Direction

The current `Opportunity` model is not the right long-term response shape for this feature because it does not expose the full kolab discovery surface:

- `needs`
- `community_types`
- `community_size`
- `typical_attendance`
- `offers_in_return`
- `venue_preference`
- `offering`
- `seeking_communities`
- `min_community_size`
- `expects`
- `venue_type`
- `product_type`
- `intent_type`

The mobile app should move to a new discovery response model instead of forcing these fields into the old `Opportunity` contract.

## Backend Dependency

Preferred backend contract:

- new authenticated discovery endpoint backed by published `kolabs`
- normalized discovery response shape
- feed mode support: `recommended` and `all`
- role-aware filtering
- fit metadata returned by backend

Detailed backend expectations are documented separately for the Laravel repo.

## Non-Goals

- redesigning swipe cards from scratch
- advanced desktop-style faceted search
- free-text search as the main discovery mechanism
- audience-size auto-fit for community viewers before profile data exists
