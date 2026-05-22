import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/auth/providers/auth_provider.dart';
import 'package:kolabing_app/features/discovery/models/discovery_filters.dart';
import 'package:kolabing_app/features/discovery/providers/discovery_provider.dart';
import 'package:kolabing_app/widgets/explore_filter_sheet.dart';

void main() {
  testWidgets('business viewer sees community request filters', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
            () => _FakeAuthNotifier(
              AuthState(
                status: AuthStatus.authenticated,
                user: _user(UserType.business),
              ),
            ),
          ),
          discoveryFiltersProvider.overrideWith(
            _FakeDiscoveryFiltersNotifier.new,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ExploreFilterSheet(totalResults: 15)),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Search & Filter'), findsOneWidget);
    expect(find.text('Need'), findsOneWidget);
    expect(find.text('Community Type'), findsOneWidget);
    expect(find.text('Audience Size'), findsOneWidget);
    expect(find.text('Kolab Type'), findsNothing);
  });

  testWidgets('community viewer sees business offer filters and search', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
            () => _FakeAuthNotifier(
              AuthState(
                status: AuthStatus.authenticated,
                user: _user(UserType.community),
              ),
            ),
          ),
          discoveryFiltersProvider.overrideWith(
            _FakeDiscoveryFiltersNotifier.new,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ExploreFilterSheet(totalResults: 15)),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Kolab Type'), findsOneWidget);
    expect(find.text('What They Offer'), findsOneWidget);
    expect(find.text('Venue Type'), findsOneWidget);
    expect(find.text('Product Type'), findsOneWidget);
    expect(
      find.text('Search by title, description, or creator...'),
      findsOneWidget,
    );
  });
}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._initialState);

  final AuthState _initialState;

  @override
  AuthState build() => _initialState;
}

class _FakeDiscoveryFiltersNotifier extends DiscoveryFiltersNotifier {
  @override
  DiscoveryFilters build() => const DiscoveryFilters();
}

UserModel _user(UserType type) =>
    UserModel(id: 'user-1', email: 'user@example.com', userType: type);
