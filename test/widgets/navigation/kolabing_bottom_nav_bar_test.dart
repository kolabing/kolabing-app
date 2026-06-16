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

    // The nav renders labels upper-cased; long labels stay on a single line
    // and clip with an ellipsis rather than wrapping or overflowing.
    final label = tester.widget<Text>(find.text('MY OPPORTUNITIES'));
    expect(label.maxLines, 1);
    expect(label.overflow, TextOverflow.ellipsis);
  });
}

void _noop(int _) {}
