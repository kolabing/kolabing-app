import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/widgets/navigation/kolabing_bottom_nav_bar.dart';
import 'package:lucide_icons/lucide_icons.dart';

void main() {
  testWidgets('long labels scale down inside bottom navigation items', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(size: Size(320, 800)),
        child: MaterialApp(
          home: Scaffold(
            bottomNavigationBar: KolabingBottomNavBar(
              items: [
                NavItem(
                  icon: LucideIcons.home,
                  activeIcon: LucideIcons.home,
                  label: 'Home',
                ),
                NavItem(
                  icon: LucideIcons.compass,
                  activeIcon: LucideIcons.compass,
                  label: 'Explore',
                ),
                NavItem(
                  icon: LucideIcons.star,
                  activeIcon: LucideIcons.star,
                  label: 'My Opportunities',
                ),
                NavItem(
                  icon: LucideIcons.send,
                  activeIcon: LucideIcons.send,
                  label: 'Applications',
                ),
                NavItem(
                  icon: LucideIcons.user,
                  activeIcon: LucideIcons.user,
                  label: 'Profile',
                ),
              ],
              currentIndex: 2,
              onTap: _noop,
            ),
          ),
        ),
      ),
    );

    // The nav renders labels upper-cased; the selected item's label scales to
    // fit via a FittedBox.
    expect(
      find.ancestor(
        of: find.text('MY OPPORTUNITIES'),
        matching: find.byType(FittedBox),
      ),
      findsOneWidget,
    );
  });
}

void _noop(int _) {}
