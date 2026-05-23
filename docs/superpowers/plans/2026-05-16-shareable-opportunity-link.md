# Shareable Opportunity Link Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add public share URLs for published opportunities, open them inside the app on `/c/:id`, preserve apply intent through auth, and scaffold the Branch/App Link integration needed for deferred deep linking.

**Architecture:** Reuse the existing `Opportunity` detail/apply flow as the single public share target. Add a small share utility, a deep-link parser/router service, and a persisted pending-destination service so unauthenticated users can return to the same opportunity after auth/onboarding. Use verified `https` routes plus Branch SDK hooks; the public web preview, OG rendering, AASA, and `assetlinks.json` remain external dependencies.

**Tech Stack:** Flutter, Riverpod, GoRouter, `share_plus`, `shared_preferences`, `app_links`, `flutter_branch_sdk`, Android App Links, iOS Associated Domains/Universal Links

---

## External Prerequisites

These items are required for acceptance criteria 2, 4, and 5, but they are **not executable inside this repo**:

- `kolabing.com` must serve `https://kolabing.com/c/<id>` as a public server-rendered page for published opportunities.
- That page must emit OG metadata and an image preview that works in WhatsApp, Instagram DM, iMessage, Slack, and email.
- `https://kolabing.com/.well-known/apple-app-site-association` must authorize `applinks:kolabing.com` for the iOS bundle `com.kolabing.kolabingApp`.
- `https://kolabing.com/.well-known/assetlinks.json` must authorize the Android package `com.kolabing.kolabing_app` with the **Play App Signing** SHA-256 fingerprint.
- Branch dashboard configuration must provide:
  - a live Branch key
  - a test Branch key
  - a link domain or canonical URL rules that preserve `entity_type=opportunity`, `entity_id=<id>`, and `open_apply=true|false`
  - App Store and Play Store destinations

Do not claim the ticket complete until these external deliverables are live and manual device verification passes.

### Task 1: Canonical Share Utility And Post-Publish Share CTA

**Files:**
- Create: `lib/features/opportunity/utils/opportunity_share.dart`
- Modify: `lib/features/community/screens/create_opportunity_screen.dart`
- Test: `test/features/opportunity/utils/opportunity_share_test.dart`

- [ ] **Step 1: Write the failing share utility tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/opportunity/utils/opportunity_share.dart';

void main() {
  test('buildOpportunitySharePath returns the canonical in-app path', () {
    expect(buildOpportunitySharePath('opp-42'), '/c/opp-42');
  });

  test('buildOpportunitySharePath appends apply=1 when requested', () {
    expect(
      buildOpportunitySharePath('opp-42', apply: true),
      '/c/opp-42?apply=1',
    );
  });

  test('buildOpportunityShareMessage includes the title and web URL', () {
    expect(
      buildOpportunityShareMessage(
        title: 'Sunset Rooftop Collab',
        opportunityId: 'opp-42',
      ),
      'Check out "Sunset Rooftop Collab" on Kolabing: https://kolabing.com/c/opp-42',
    );
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/opportunity/utils/opportunity_share_test.dart`

Expected: FAIL with a missing import or undefined share helpers because `opportunity_share.dart` does not exist yet.

- [ ] **Step 3: Implement the share helper and wire the publish success dialog**

```dart
// lib/features/opportunity/utils/opportunity_share.dart
const String _kolabingShareHost = 'kolabing.com';

String buildOpportunitySharePath(String opportunityId, {bool apply = false}) =>
    Uri(
      path: '/c/$opportunityId',
      queryParameters: apply ? const <String, String>{'apply': '1'} : null,
    ).toString();

Uri buildOpportunityShareUri(String opportunityId, {bool apply = false}) =>
    Uri.https(
      _kolabingShareHost,
      '/c/$opportunityId',
      apply ? const <String, String>{'apply': '1'} : null,
    );

String buildOpportunityShareMessage({
  required String title,
  required String opportunityId,
}) =>
    'Check out "$title" on Kolabing: ${buildOpportunityShareUri(opportunityId)}';
```

```dart
// lib/features/community/screens/create_opportunity_screen.dart
import 'package:share_plus/share_plus.dart';

import '../../opportunity/utils/opportunity_share.dart';

Future<void> _handlePublish() async {
  final success = await ref.read(opportunityFormProvider.notifier).saveAndPublish();
  if (success && mounted) {
    final opportunity = ref.read(opportunityFormProvider).opportunity;
    _showSuccessDialog(isDraft: false, opportunity: opportunity);
  }
}

Future<void> _sharePublishedOpportunity(Opportunity opportunity) async {
  final opportunityId = opportunity.id;
  if (opportunityId == null || opportunityId.isEmpty) {
    return;
  }

  await Share.share(
    buildOpportunityShareMessage(
      title: opportunity.title,
      opportunityId: opportunityId,
    ),
  );
}

void _showSuccessDialog({
  required bool isDraft,
  Opportunity? opportunity,
}) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: KolabingRadius.borderRadiusLg,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: KolabingColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.checkCircle,
              size: 48,
              color: KolabingColors.success,
            ),
          ),
          const SizedBox(height: KolabingSpacing.md),
          Text(
            isDraft ? 'Draft Saved!' : 'Opportunity Published!',
            style: GoogleFonts.rubik(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: KolabingColors.textPrimary,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            isDraft
                ? 'Your kolab has been saved as a draft. You can edit and publish it later.'
                : 'Your kolab is now live. Businesses can start applying!',
            style: GoogleFonts.openSans(
              fontSize: 14,
              color: KolabingColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        if (!isDraft && opportunity?.id != null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _sharePublishedOpportunity(opportunity!),
              child: const Text('SHARE'),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: KolabingColors.primary,
              foregroundColor: KolabingColors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: KolabingRadius.borderRadiusMd,
              ),
            ),
            child: Text(
              'VIEW MY OPPORTUNITIES',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/features/opportunity/utils/opportunity_share_test.dart`

Expected: PASS for all three share helper tests.

- [ ] **Step 5: Commit**

```bash
git add test/features/opportunity/utils/opportunity_share_test.dart lib/features/opportunity/utils/opportunity_share.dart lib/features/community/screens/create_opportunity_screen.dart
git commit -m "feat: add canonical opportunity share helper"
```

### Task 2: Fix The Community Opportunity Surface And Add Share Actions

**Files:**
- Modify: `lib/features/community/screens/community_main_screen.dart`
- Modify: `lib/features/community/screens/my_opportunities_screen.dart`
- Modify: `lib/features/community/widgets/my_opportunity_card.dart`
- Test: `test/features/community/widgets/my_opportunity_card_test.dart`

- [ ] **Step 1: Write the failing widget test for published opportunity share actions**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/community/widgets/my_opportunity_card.dart';
import 'package:kolabing_app/features/opportunity/models/opportunity.dart';

void main() {
  testWidgets('published opportunities show the Share action', (tester) async {
    final opportunity = Opportunity.empty().copyWith(
      id: 'opp-42',
      title: 'Sunset Rooftop Collab',
      preferredCity: 'Barcelona',
      status: OpportunityStatus.published,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MyOpportunityCard(
            opportunity: opportunity,
            onEdit: () {},
            onShare: () {},
            onClose: () {},
          ),
        ),
      ),
    );

    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/community/widgets/my_opportunity_card_test.dart`

Expected: FAIL because `MyOpportunityCard` does not yet expose `onShare` or render a Share action.

- [ ] **Step 3: Switch the screen to the Opportunity stack and add Share buttons**

```dart
// lib/features/community/widgets/my_opportunity_card.dart
class MyOpportunityCard extends StatelessWidget {
  const MyOpportunityCard({
    required this.opportunity,
    super.key,
    this.onEdit,
    this.onPublish,
    this.onShare,
    this.onClose,
    this.onDelete,
  });

  final Opportunity opportunity;
  final VoidCallback? onEdit;
  final VoidCallback? onPublish;
  final VoidCallback? onShare;
  final VoidCallback? onClose;
  final VoidCallback? onDelete;

  Widget _buildActions() {
    final status = opportunity.status;
    final actions = <Widget>[];

    if (status.canEdit && onEdit != null) {
      actions.add(
        _ActionButton(
          label: 'Edit',
          icon: LucideIcons.edit,
          onTap: onEdit!,
          outlined: true,
        ),
      );
    }

    if (status.canPublish && onPublish != null) {
      actions.add(
        _ActionButton(
          label: 'Publish',
          icon: LucideIcons.upload,
          onTap: onPublish!,
          primary: true,
        ),
      );
    }

    if (status == OpportunityStatus.published && onShare != null) {
      actions.add(
        _ActionButton(
          label: 'Share',
          icon: LucideIcons.share2,
          onTap: onShare!,
          outlined: true,
        ),
      );
    }

    if (status.canClose && onClose != null) {
      actions.add(
        _ActionButton(
          label: 'Close',
          icon: LucideIcons.xCircle,
          onTap: onClose!,
          outlined: true,
        ),
      );
    }

    if (status.canDelete &&
        (opportunity.applicationsCount ?? 0) == 0 &&
        onDelete != null) {
      actions.add(
        _ActionButton(
          label: 'Delete',
          icon: LucideIcons.trash2,
          onTap: onDelete!,
          danger: true,
        ),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Row(
      children: actions
          .expand(
            (widget) => <Widget>[
              Expanded(child: widget),
              const SizedBox(width: KolabingSpacing.xs),
            ],
          )
          .toList()
        ..removeLast(),
    );
  }
}
```

```dart
// lib/features/community/screens/community_main_screen.dart
Future<void> _onFabPressed() async {
  await context.push(KolabingRoutes.communityOpportunitiesNew);
  if (mounted) {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      ref
        ..invalidate(dashboardProvider)
        ..invalidate(myOpportunitiesProvider);
    }
  }
}
```

```dart
// lib/features/community/screens/my_opportunities_screen.dart
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../opportunity/models/opportunity.dart';
import '../../opportunity/providers/opportunity_provider.dart';
import '../../opportunity/utils/opportunity_share.dart';
import '../widgets/my_opportunity_card.dart';

class _MyOpportunitiesScreenState extends ConsumerState<MyOpportunitiesScreen> {
  final _scrollController = ScrollController();

  static const _statusTabs = [
    (label: 'All', value: null),
    (label: 'Draft', value: 'draft'),
    (label: 'Published', value: 'published'),
    (label: 'Closed', value: 'closed'),
  ];

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(myOpportunitiesProvider.notifier).loadMore();
    }
  }

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(
      KolabingSpacing.md,
      KolabingSpacing.md,
      KolabingSpacing.md,
      KolabingSpacing.xs,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MY OPPORTUNITIES',
          style: KolabingTextStyles.pageTitle.copyWith(
            color: KolabingColors.textPrimary,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xxs),
        Text(
          'Create and manage your opportunities',
          style: GoogleFonts.openSans(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: KolabingColors.textSecondary,
          ),
        ),
      ],
    ),
  );

  void _onCreateNew() {
    context.push(KolabingRoutes.communityOpportunitiesNew);
  }

  void _onEdit(Opportunity opportunity) {
    context.push(KolabingRoutes.communityOpportunitiesEdit, extra: opportunity);
  }

  Future<void> _shareOpportunity(Opportunity opportunity) async {
    final opportunityId = opportunity.id;
    if (opportunityId == null || opportunityId.isEmpty) {
      return;
    }

    final message = buildOpportunityShareMessage(
      title: opportunity.title,
      opportunityId: opportunityId,
    );

    try {
      final result = await Share.share(message);
      if (result.status == ShareResultStatus.unavailable && mounted) {
        await Clipboard.setData(ClipboardData(text: message));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sharing is unavailable. Link copied instead.'),
              backgroundColor: KolabingColors.textPrimary,
            ),
          );
        }
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the share sheet.'),
          backgroundColor: KolabingColors.error,
        ),
      );
    }
  }

  Future<void> _onPublish(String id) async {
    final success = await ref.read(myOpportunitiesProvider.notifier).publish(id);
    if (mounted) {
      final state = ref.read(myOpportunitiesProvider);
      final errorMessage = state.error ?? 'Failed to publish';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Opportunity published!' : errorMessage),
          behavior: SnackBarBehavior.floating,
          backgroundColor: success
              ? KolabingColors.success
              : KolabingColors.error,
        ),
      );
    }
  }

  Future<void> _onClose(String id) async {
    final success = await ref.read(myOpportunitiesProvider.notifier).close(id);
    if (mounted) {
      final state = ref.read(myOpportunitiesProvider);
      final errorMessage = state.error ?? 'Failed to close';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Opportunity closed' : errorMessage),
          behavior: SnackBarBehavior.floating,
          backgroundColor: success
              ? KolabingColors.success
              : KolabingColors.error,
        ),
      );
    }
  }

  Future<void> _onDelete(String id) async {
    final success = await ref.read(myOpportunitiesProvider.notifier).delete(id);
    if (mounted) {
      final state = ref.read(myOpportunitiesProvider);
      final errorMessage = state.error ?? 'Failed to delete';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Opportunity deleted' : errorMessage),
          behavior: SnackBarBehavior.floating,
          backgroundColor: success
              ? KolabingColors.success
              : KolabingColors.error,
        ),
      );
    }
  }
}
```

```dart
// lib/features/community/screens/my_opportunities_screen.dart
@override
Widget build(BuildContext context) {
  final listState = ref.watch(myOpportunitiesProvider);
  final currentStatus = ref.watch(myOpportunitiesStatusProvider);

  return Scaffold(
    backgroundColor: KolabingColors.background,
    body: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildStatusTabs(currentStatus),
          Expanded(
            child: listState.isLoading
                ? _buildLoadingState()
                : listState.error != null
                    ? _buildErrorState(listState.error!)
                    : listState.isEmpty
                        ? _buildEmptyState()
                        : _buildList(listState),
          ),
        ],
      ),
    ),
  );
}
```

```dart
// lib/features/community/screens/my_opportunities_screen.dart
Widget _buildList(OpportunityListState listState) => Column(
  children: [
    Expanded(
      child: RefreshIndicator(
        color: KolabingColors.primary,
        onRefresh: () async {
          await ref.read(myOpportunitiesProvider.notifier).refresh();
        },
        child: ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(
            KolabingSpacing.md,
            0,
            KolabingSpacing.md,
            KolabingSpacing.xxl,
          ),
          itemCount:
              listState.opportunities.length + (listState.isLoadingMore ? 1 : 0),
          separatorBuilder: (context, index) =>
              const SizedBox(height: KolabingSpacing.sm),
          itemBuilder: (context, index) {
            if (index >= listState.opportunities.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(KolabingSpacing.md),
                  child: CircularProgressIndicator(
                    color: KolabingColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              );
            }

            final opportunity = listState.opportunities[index];
            return MyOpportunityCard(
              opportunity: opportunity,
              onEdit: () => _onEdit(opportunity),
              onPublish: opportunity.id != null
                  ? () => _onPublish(opportunity.id!)
                  : null,
              onShare: opportunity.id != null
                  ? () => _shareOpportunity(opportunity)
                  : null,
              onClose: opportunity.id != null
                  ? () => _onClose(opportunity.id!)
                  : null,
              onDelete: opportunity.id != null
                  ? () => _onDelete(opportunity.id!)
                  : null,
            );
          },
        ),
      ),
    ),
  ],
);
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/features/community/widgets/my_opportunity_card_test.dart`

Expected: PASS with the Share button rendered for published opportunities.

- [ ] **Step 5: Commit**

```bash
git add test/features/community/widgets/my_opportunity_card_test.dart lib/features/community/screens/community_main_screen.dart lib/features/community/screens/my_opportunities_screen.dart lib/features/community/widgets/my_opportunity_card.dart
git commit -m "fix: align community opportunities screen with opportunity share flow"
```

### Task 3: Add The Public `/c/:id` Route And An `https` Deep-Link Listener

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/config/routes/routes.dart`
- Modify: `lib/main.dart`
- Create: `lib/services/deep_link_destination_parser.dart`
- Create: `lib/services/deep_link_service.dart`
- Test: `test/services/deep_link_destination_parser_test.dart`
- Test: `test/config/routes/public_opportunity_share_route_test.dart`

- [ ] **Step 1: Write the failing parser and route tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/services/deep_link_destination_parser.dart';

void main() {
  test('parses the canonical Kolabing opportunity URL', () {
    expect(
      parseKolabingDeepLink(Uri.parse('https://kolabing.com/c/opp-42')),
      '/c/opp-42',
    );
  });

  test('preserves apply=1 when present', () {
    expect(
      parseKolabingDeepLink(Uri.parse('https://kolabing.com/c/opp-42?apply=1')),
      '/c/opp-42?apply=1',
    );
  });

  test('ignores non-Kolabing hosts', () {
    expect(
      parseKolabingDeepLink(Uri.parse('https://example.com/c/opp-42')),
      isNull,
    );
  });
}
```

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/config/routes/routes.dart';
import 'package:kolabing_app/features/business/screens/community_offer_detail_screen.dart';

void main() {
  testWidgets('navigating to /c/:id builds the public opportunity detail route', (
    tester,
  ) async {
    kolabingRouter.go(KolabingRoutes.publicOpportunitySharePath('opp-42'));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp.router(routerConfig: kolabingRouter),
      ),
    );

    await tester.pump();

    expect(find.byType(CommunityOfferDetailScreen), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/services/deep_link_destination_parser_test.dart test/config/routes/public_opportunity_share_route_test.dart`

Expected: FAIL because the parser/service files and the `/c/:id` route do not exist yet.

- [ ] **Step 3: Implement the new route, parser, service, and app startup hook**

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  app_links: ^6.4.1
```

```dart
// lib/config/routes/routes.dart
abstract final class KolabingRoutes {
  static const String publicOpportunityShare = '/c/:id';

  static String publicOpportunitySharePath(String id, {bool apply = false}) =>
      Uri(
        path: '/c/$id',
        queryParameters: apply ? const <String, String>{'apply': '1'} : null,
      ).toString();
}

GoRoute(
  path: KolabingRoutes.publicOpportunityShare,
  name: 'publicOpportunityShare',
  builder: (BuildContext context, GoRouterState state) {
    final id = state.pathParameters['id'] ?? '';
    return CommunityOfferDetailScreen(offerId: id);
  },
),
```

```dart
// lib/services/deep_link_destination_parser.dart
import '../config/routes/routes.dart';

String? parseKolabingDeepLink(Uri uri) {
  final isHttps = uri.scheme.toLowerCase() == 'https';
  final host = uri.host.toLowerCase();
  if (!isHttps || host != 'kolabing.com') {
    return null;
  }

  final segments = uri.pathSegments.where((segment) => segment.isNotEmpty).toList();
  if (segments.length == 2 && segments.first == 'c') {
    return KolabingRoutes.publicOpportunitySharePath(
      segments[1],
      apply: uri.queryParameters['apply'] == '1',
    );
  }

  return null;
}
```

```dart
// lib/services/deep_link_service.dart
import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'deep_link_destination_parser.dart';

class DeepLinkService {
  DeepLinkService({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  static final DeepLinkService instance = DeepLinkService();

  final AppLinks _appLinks;
  StreamSubscription<Uri>? _uriSubscription;

  Future<void> connectRouter(GoRouter router) async {
    final initialUri = await _appLinks.getInitialAppLink();
    _dispatchUri(initialUri, router, replace: true);

    _uriSubscription ??= _appLinks.uriLinkStream.listen(
      (uri) => _dispatchUri(uri, router),
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('AppLinks stream error: $error');
      },
    );
  }

  void _dispatchUri(Uri? uri, GoRouter router, {bool replace = false}) {
    if (uri == null) {
      return;
    }

    final route = parseKolabingDeepLink(uri);
    if (route == null) {
      return;
    }

    if (replace) {
      router.go(route);
    } else {
      router.push(route);
    }
  }

  Future<void> dispose() async {
    await _uriSubscription?.cancel();
    _uriSubscription = null;
  }
}
```

```dart
// lib/config/routes/routes.dart
import '../../services/deep_link_service.dart';

Future<void> connectDeepLinkRouter() async {
  await DeepLinkService.instance.connectRouter(kolabingRouter);
}
```

```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.instance.initialize();
  connectNotificationRouter();
  await connectDeepLinkRouter();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
    const ProviderScope(
      child: KolabingApp(),
    ),
  );
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/services/deep_link_destination_parser_test.dart test/config/routes/public_opportunity_share_route_test.dart`

Expected: PASS for the parser tests and route build test.

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml lib/config/routes/routes.dart lib/main.dart lib/services/deep_link_destination_parser.dart lib/services/deep_link_service.dart test/services/deep_link_destination_parser_test.dart test/config/routes/public_opportunity_share_route_test.dart
git commit -m "feat: add public opportunity share route"
```

### Task 4: Persist Pending Destinations And Resume Them After Auth

**Files:**
- Create: `lib/services/pending_destination_service.dart`
- Create: `lib/features/auth/utils/post_auth_destination_resolver.dart`
- Modify: `lib/features/auth/screens/login_screen.dart`
- Modify: `lib/features/auth/providers/auth_state_provider.dart`
- Modify: `lib/features/onboarding/screens/business/business_final_screen.dart`
- Test: `test/services/pending_destination_service_test.dart`
- Test: `test/features/auth/utils/post_auth_destination_resolver_test.dart`

- [ ] **Step 1: Write the failing pending-destination tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kolabing_app/services/pending_destination_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('stores and reads the pending destination', () async {
    final service = PendingDestinationService.instance;

    await service.set('/c/opp-42?apply=1');

    expect(await service.peek(), '/c/opp-42?apply=1');
  });

  test('clear removes the pending destination', () async {
    final service = PendingDestinationService.instance;

    await service.set('/c/opp-42?apply=1');
    await service.clear();

    expect(await service.peek(), isNull);
  });
}
```

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/config/routes/routes.dart';
import 'package:kolabing_app/features/auth/utils/post_auth_destination_resolver.dart';

void main() {
  test('existing business users return to the pending opportunity route', () {
    final decision = resolvePostAuthDestination(
      defaultRoute: KolabingRoutes.businessDashboard,
      isBusinessUser: true,
      isNewUser: false,
      hasShownPermissions: true,
      pendingDestination: '/c/opp-42?apply=1',
    );

    expect(decision.route, '/c/opp-42?apply=1');
    expect(decision.clearPendingDestination, isTrue);
  });

  test('new business users still go through onboarding first', () {
    final decision = resolvePostAuthDestination(
      defaultRoute: KolabingRoutes.businessOnboardingStep2,
      isBusinessUser: true,
      isNewUser: true,
      hasShownPermissions: true,
      pendingDestination: '/c/opp-42?apply=1',
    );

    expect(decision.route, KolabingRoutes.businessOnboardingStep2);
    expect(decision.clearPendingDestination, isFalse);
  });

  test('permission wrapping preserves the pending destination', () {
    final decision = resolvePostAuthDestination(
      defaultRoute: KolabingRoutes.businessDashboard,
      isBusinessUser: true,
      isNewUser: false,
      hasShownPermissions: false,
      pendingDestination: '/c/opp-42?apply=1',
    );

    expect(
      decision.route,
      '${KolabingRoutes.permissions}?destination=%2Fc%2Fopp-42%3Fapply%3D1',
    );
    expect(decision.clearPendingDestination, isTrue);
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/services/pending_destination_service_test.dart test/features/auth/utils/post_auth_destination_resolver_test.dart`

Expected: FAIL because the service and resolver files do not exist yet.

- [ ] **Step 3: Implement the persistence service, resolver, and resume hooks**

```dart
// lib/services/pending_destination_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class PendingDestinationService {
  PendingDestinationService._();

  static final PendingDestinationService instance = PendingDestinationService._();

  static const String _key = 'pending_destination';

  Future<void> set(String destination) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, destination);
  }

  Future<String?> peek() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
```

```dart
// lib/features/auth/utils/post_auth_destination_resolver.dart
import '../../../config/routes/routes.dart';

class PostAuthDestinationDecision {
  const PostAuthDestinationDecision({
    required this.route,
    required this.clearPendingDestination,
  });

  final String route;
  final bool clearPendingDestination;
}

PostAuthDestinationDecision resolvePostAuthDestination({
  required String defaultRoute,
  required bool isBusinessUser,
  required bool isNewUser,
  required bool hasShownPermissions,
  required String? pendingDestination,
}) {
  String wrapWithPermissions(String route) =>
      '${KolabingRoutes.permissions}?destination=${Uri.encodeComponent(route)}';

  if (isNewUser) {
    return PostAuthDestinationDecision(
      route: hasShownPermissions ? defaultRoute : wrapWithPermissions(defaultRoute),
      clearPendingDestination: false,
    );
  }

  final hasPendingOpportunity =
      pendingDestination != null && pendingDestination.startsWith('/c/');
  final route =
      isBusinessUser && hasPendingOpportunity ? pendingDestination! : defaultRoute;

  return PostAuthDestinationDecision(
    route: hasShownPermissions ? route : wrapWithPermissions(route),
    clearPendingDestination: hasPendingOpportunity,
  );
}
```

```dart
// lib/features/auth/screens/login_screen.dart
import '../utils/post_auth_destination_resolver.dart';
import '../../../services/pending_destination_service.dart';

Future<String> _getNavigationRoute(AuthResult result) async {
  final user = result.user;
  if (user == null) {
    return KolabingRoutes.welcome;
  }

  final defaultRoute = resolveAuthDestination(
    user,
    isNewUser: result.isNewUser,
  );

  final hasShownPermissions = await PermissionService.instance
      .hasShownPermissionScreen();
  final pendingDestination = await PendingDestinationService.instance.peek();
  final decision = resolvePostAuthDestination(
    defaultRoute: defaultRoute,
    isBusinessUser: user.isBusiness,
    isNewUser: result.isNewUser,
    hasShownPermissions: hasShownPermissions,
    pendingDestination: pendingDestination,
  );

  if (decision.clearPendingDestination) {
    await PendingDestinationService.instance.clear();
  }

  return decision.route;
}
```

```dart
// lib/features/auth/providers/auth_state_provider.dart
import '../../../services/pending_destination_service.dart';
import '../utils/post_auth_destination_resolver.dart';

Future<String> initialize() async {
  try {
    final authService = AuthService();
    final token = await authService.getToken();
    final storedUser = await authService.getStoredUser();

    if (token == null) {
      state = state.copyWith(
        isLoading: false,
        navigationTarget: SplashNavigationTarget.welcome,
      );
      return KolabingRoutes.welcome;
    }

    final user = await authService.restoreSessionUser() ?? storedUser;
    if (user == null) {
      state = state.copyWith(
        isLoading: false,
        navigationTarget: SplashNavigationTarget.welcome,
      );
      return KolabingRoutes.welcome;
    }

    final String dashboard;
    final SplashNavigationTarget navTarget;
    if (user.isAttendee) {
      dashboard = KolabingRoutes.attendeeDashboard;
      navTarget = SplashNavigationTarget.attendeeDashboard;
    } else if (user.isBusiness) {
      dashboard = KolabingRoutes.businessDashboard;
      navTarget = SplashNavigationTarget.businessDashboard;
    } else {
      dashboard = KolabingRoutes.communityDashboard;
      navTarget = SplashNavigationTarget.communityDashboard;
    }

    final hasShownPermissions = await PermissionService.instance
        .hasShownPermissionScreen();
    final pendingDestination = await PendingDestinationService.instance.peek();
    final decision = resolvePostAuthDestination(
      defaultRoute: dashboard,
      isBusinessUser: user.isBusiness,
      isNewUser: false,
      hasShownPermissions: hasShownPermissions,
      pendingDestination: pendingDestination,
    );

    if (decision.clearPendingDestination) {
      await PendingDestinationService.instance.clear();
    }

    state = state.copyWith(isLoading: false, navigationTarget: navTarget);
    return decision.route;
  } on Exception catch (e) {
    state = state.copyWith(
      isLoading: false,
      navigationTarget: SplashNavigationTarget.welcome,
      errorMessage: 'Failed to initialize: $e',
    );
    return KolabingRoutes.welcome;
  }
}
```

```dart
// lib/features/onboarding/screens/business/business_final_screen.dart
import '../../../services/pending_destination_service.dart';
import '../../auth/utils/post_auth_destination_resolver.dart';

final hasShownPermissions = await PermissionService.instance
    .hasShownPermissionScreen();
if (!mounted) return;

final pendingDestination = await PendingDestinationService.instance.peek();
final decision = resolvePostAuthDestination(
  defaultRoute: KolabingRoutes.businessDashboard,
  isBusinessUser: true,
  isNewUser: false,
  hasShownPermissions: hasShownPermissions,
  pendingDestination: pendingDestination,
);

if (decision.clearPendingDestination) {
  await PendingDestinationService.instance.clear();
}

if (!mounted) return;
context.go(decision.route);
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/services/pending_destination_service_test.dart test/features/auth/utils/post_auth_destination_resolver_test.dart`

Expected: PASS with pending destinations persisted, cleared, and wrapped correctly.

- [ ] **Step 5: Commit**

```bash
git add lib/services/pending_destination_service.dart lib/features/auth/utils/post_auth_destination_resolver.dart lib/features/auth/screens/login_screen.dart lib/features/auth/providers/auth_state_provider.dart lib/features/onboarding/screens/business/business_final_screen.dart test/services/pending_destination_service_test.dart test/features/auth/utils/post_auth_destination_resolver_test.dart
git commit -m "feat: resume shared opportunity destinations after auth"
```

### Task 5: Gate Apply Entry And Auto-Open The Apply Flow From Shared Links

**Files:**
- Create: `lib/features/application/utils/apply_entry_guard.dart`
- Modify: `lib/features/business/screens/community_offer_detail_screen.dart`
- Test: `test/features/application/utils/apply_entry_guard_test.dart`

- [ ] **Step 1: Write the failing apply-entry guard tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/application/utils/apply_entry_guard.dart';
import 'package:kolabing_app/features/auth/providers/auth_provider.dart';

void main() {
  test('unauthenticated users are sent to login', () {
    expect(
      resolveApplyEntryDisposition(const AuthState(status: AuthStatus.unauthenticated)),
      ApplyEntryDisposition.requireLogin,
    );
  });

  test('authenticated business users can open the apply modal', () {
    expect(
      resolveApplyEntryDisposition(
        AuthState(
          status: AuthStatus.authenticated,
          user: const UserModel(
            id: 'biz-1',
            email: 'biz@kolabing.com',
            userType: UserType.business,
          ),
        ),
      ),
      ApplyEntryDisposition.openApplyModal,
    );
  });

  test('authenticated non-business users see the business-only gate', () {
    expect(
      resolveApplyEntryDisposition(
        AuthState(
          status: AuthStatus.authenticated,
          user: const UserModel(
            id: 'community-1',
            email: 'community@kolabing.com',
            userType: UserType.community,
          ),
        ),
      ),
      ApplyEntryDisposition.requireBusinessAccount,
    );
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/application/utils/apply_entry_guard_test.dart`

Expected: FAIL because `apply_entry_guard.dart` does not exist yet.

- [ ] **Step 3: Implement the apply-entry guard and use it from the public detail screen**

```dart
// lib/features/application/utils/apply_entry_guard.dart
import '../../auth/providers/auth_provider.dart';

enum ApplyEntryDisposition {
  openApplyModal,
  requireLogin,
  requireBusinessAccount,
}

ApplyEntryDisposition resolveApplyEntryDisposition(AuthState authState) {
  if (!authState.isAuthenticated) {
    return ApplyEntryDisposition.requireLogin;
  }

  if (authState.user?.isBusiness == true) {
    return ApplyEntryDisposition.openApplyModal;
  }

  return ApplyEntryDisposition.requireBusinessAccount;
}
```

```dart
// lib/features/business/screens/community_offer_detail_screen.dart
import '../../application/utils/apply_entry_guard.dart';
import '../../auth/providers/auth_provider.dart';
import '../../opportunity/utils/opportunity_share.dart';
import '../../../services/pending_destination_service.dart';

class _CommunityOfferDetailScreenState
    extends ConsumerState<CommunityOfferDetailScreen> {
  bool _hasAttemptedAutoApply = false;

  Future<void> _handleApplyEntry(Opportunity opportunity) async {
    final disposition = resolveApplyEntryDisposition(ref.read(authProvider));

    switch (disposition) {
      case ApplyEntryDisposition.openApplyModal:
        await _handleApply(opportunity);
        return;
      case ApplyEntryDisposition.requireLogin:
        final opportunityId = opportunity.id;
        if (opportunityId != null && opportunityId.isNotEmpty) {
          await PendingDestinationService.instance.set(
            buildOpportunitySharePath(opportunityId, apply: true),
          );
        }
        if (!mounted) return;
        context.go(KolabingRoutes.login);
        return;
      case ApplyEntryDisposition.requireBusinessAccount:
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Business Account Required'),
            content: const Text(
              'Only business accounts can apply to collaboration opportunities.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
        return;
    }
  }

  void _maybeAutoOpenApply(Opportunity opportunity) {
    if (_hasAttemptedAutoApply || opportunity.hasApplied == true) {
      return;
    }

    final shouldApply = GoRouterState.of(context).uri.queryParameters['apply'] == '1';
    if (!shouldApply) {
      return;
    }

    _hasAttemptedAutoApply = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handleApplyEntry(opportunity);
    });
  }
}
```

```dart
// lib/features/business/screens/community_offer_detail_screen.dart
data: (opportunity) {
  _maybeAutoOpenApply(opportunity);
  return _buildContent(opportunity);
},
```

```dart
// lib/features/business/screens/community_offer_detail_screen.dart
onPressed: () => _handleApplyEntry(opportunity),
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/features/application/utils/apply_entry_guard_test.dart`

Expected: PASS for login, business, and non-business gating.

- [ ] **Step 5: Commit**

```bash
git add lib/features/application/utils/apply_entry_guard.dart lib/features/business/screens/community_offer_detail_screen.dart test/features/application/utils/apply_entry_guard_test.dart
git commit -m "feat: gate shared opportunity apply entry"
```

### Task 6: Add Branch SDK Scaffolding And Platform-Level Link Configuration

**Files:**
- Modify: `.gitignore`
- Modify: `pubspec.yaml`
- Modify: `lib/services/deep_link_destination_parser.dart`
- Modify: `lib/services/deep_link_service.dart`
- Modify: `android/app/build.gradle.kts`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `ios/Flutter/Debug.xcconfig`
- Modify: `ios/Flutter/Release.xcconfig`
- Create: `ios/Flutter/Branch.xcconfig.example`
- Modify: `ios/Runner/Info.plist`
- Modify: `ios/Runner/Runner.entitlements`
- Test: `test/services/deep_link_destination_parser_test.dart`

- [ ] **Step 1: Extend the parser test with a Branch payload case**

```dart
test('parses Branch payloads into the same share route', () {
  expect(
    parseBranchSharePayload(<dynamic, dynamic>{
      '+clicked_branch_link': true,
      'entity_type': 'opportunity',
      'entity_id': 'opp-42',
      'open_apply': '1',
    }),
    '/c/opp-42?apply=1',
  );
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/services/deep_link_destination_parser_test.dart`

Expected: FAIL because Branch payload parsing is not implemented yet.

- [ ] **Step 3: Add the Branch SDK, platform config scaffolding, and Branch listener**

```gitignore
# .gitignore
ios/Flutter/Branch.xcconfig
```

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  app_links: ^6.4.1
  flutter_branch_sdk: ^9.3.1
```

```dart
// lib/services/deep_link_destination_parser.dart
String? parseBranchSharePayload(Map<dynamic, dynamic> data) {
  final clicked = data['+clicked_branch_link'] == true ||
      data['+clicked_branch_link']?.toString().toLowerCase() == 'true';
  if (!clicked) {
    return null;
  }

  if (data['entity_type']?.toString() != 'opportunity') {
    return null;
  }

  final entityId = data['entity_id']?.toString();
  if (entityId == null || entityId.isEmpty) {
    return null;
  }

  final openApplyValue = data['open_apply']?.toString().toLowerCase();
  final openApply = openApplyValue == '1' || openApplyValue == 'true';

  return KolabingRoutes.publicOpportunitySharePath(
    entityId,
    apply: openApply,
  );
}
```

```dart
// lib/services/deep_link_service.dart
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';

class DeepLinkService {
  StreamSubscription<Map>? _branchSubscription;

  Future<void> connectRouter(GoRouter router) async {
    final initialUri = await _appLinks.getInitialAppLink();
    _dispatchUri(initialUri, router, replace: true);

    _uriSubscription ??= _appLinks.uriLinkStream.listen(
      (uri) => _dispatchUri(uri, router),
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('AppLinks stream error: $error');
      },
    );

    await _connectBranch(router);
  }

  Future<void> _connectBranch(GoRouter router) async {
    try {
      await FlutterBranchSdk.init(enableLogging: false);
      _branchSubscription ??= FlutterBranchSdk.listSession().listen(
        (data) {
          final route = parseBranchSharePayload(data);
          if (route != null) {
            router.go(route);
          }
        },
        onError: (Object error) {
          debugPrint('Branch session error: $error');
        },
      );
    } catch (error) {
      debugPrint('Branch initialization skipped: $error');
    }
  }

  Future<void> dispose() async {
    await _uriSubscription?.cancel();
    await _branchSubscription?.cancel();
    _uriSubscription = null;
    _branchSubscription = null;
  }
}
```

```kotlin
// android/app/build.gradle.kts
android {
    defaultConfig {
        applicationId = "com.kolabing.kolabing_app"
        manifestPlaceholders["BRANCH_KEY_LIVE"] =
            providers.gradleProperty("BRANCH_KEY_LIVE").orElse("").get()
        manifestPlaceholders["BRANCH_KEY_TEST"] =
            providers.gradleProperty("BRANCH_KEY_TEST").orElse("").get()
    }
}
```

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<application
    android:label="Kolabing"
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher">

    <meta-data
        android:name="io.branch.sdk.BranchKey"
        android:value="${BRANCH_KEY_LIVE}" />
    <meta-data
        android:name="io.branch.sdk.BranchKey.test"
        android:value="${BRANCH_KEY_TEST}" />
    <meta-data
        android:name="io.branch.sdk.TestMode"
        android:value="false" />

    <activity
        android:name=".MainActivity"
        android:exported="true"
        android:launchMode="singleTop"
        android:taskAffinity=""
        android:theme="@style/LaunchTheme"
        android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
        android:hardwareAccelerated="true"
        android:windowSoftInputMode="adjustResize">

        <intent-filter android:autoVerify="true">
            <action android:name="android.intent.action.VIEW" />
            <category android:name="android.intent.category.DEFAULT" />
            <category android:name="android.intent.category.BROWSABLE" />
            <data android:scheme="https" />
            <data android:host="kolabing.com" />
            <data android:pathPrefix="/c/" />
        </intent-filter>
    </activity>
</application>
```

```xcconfig
// ios/Flutter/Branch.xcconfig.example
BRANCH_KEY_LIVE=
BRANCH_KEY_TEST=
```

```xcconfig
// ios/Flutter/Debug.xcconfig
#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig"
#include "Generated.xcconfig"
#include? "Branch.xcconfig"
```

```xcconfig
// ios/Flutter/Release.xcconfig
#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig"
#include "Generated.xcconfig"
#include? "Branch.xcconfig"
```

```xml
<!-- ios/Runner/Info.plist -->
<key>branch_key</key>
<dict>
  <key>live</key>
  <string>$(BRANCH_KEY_LIVE)</string>
  <key>test</key>
  <string>$(BRANCH_KEY_TEST)</string>
</dict>
```

```xml
<!-- ios/Runner/Runner.entitlements -->
<key>com.apple.developer.associated-domains</key>
<array>
  <string>applinks:kolabing.com</string>
</array>
```

- [ ] **Step 4: Run static checks, focused tests, and manual link verification**

Run: `flutter analyze`

Expected: `No issues found!`

Run: `flutter test test/features/opportunity/utils/opportunity_share_test.dart test/features/community/widgets/my_opportunity_card_test.dart test/services/deep_link_destination_parser_test.dart test/services/pending_destination_service_test.dart test/features/auth/utils/post_auth_destination_resolver_test.dart test/features/application/utils/apply_entry_guard_test.dart test/config/routes/public_opportunity_share_route_test.dart`

Expected: PASS for every targeted test.

Run: `xcrun simctl openurl booted "https://kolabing.com/c/opp-smoke"`

Expected: The installed iOS app opens directly to the public opportunity detail route. If it opens Safari instead, the Associated Domains or AASA setup is incomplete.

Run: `adb shell am start -a android.intent.action.VIEW -d "https://kolabing.com/c/opp-smoke"`

Expected: The installed Android app opens directly to the public opportunity detail route. If it opens the browser, `assetlinks.json`, `autoVerify`, or signing fingerprints are incorrect.

- [ ] **Step 5: Commit**

```bash
git add .gitignore pubspec.yaml lib/services/deep_link_destination_parser.dart lib/services/deep_link_service.dart android/app/build.gradle.kts android/app/src/main/AndroidManifest.xml ios/Flutter/Debug.xcconfig ios/Flutter/Release.xcconfig ios/Flutter/Branch.xcconfig.example ios/Runner/Info.plist ios/Runner/Runner.entitlements test/services/deep_link_destination_parser_test.dart
git commit -m "feat: scaffold branch-backed share link configuration"
```
