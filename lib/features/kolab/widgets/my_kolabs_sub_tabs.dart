// lib/features/kolab/widgets/my_kolabs_sub_tabs.dart
import 'package:flutter/material.dart';

import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';

/// Shared underline sub-tab row for all My Kolabs sections.
///
/// Use for Published/Draft (Offers) and Sent/Received (Requests).
/// Replaces the pill-style horizontal ListView in MyKollabsScreen and
/// MyOpportunitiesScreen.
class MyKolabsSubTabs extends StatelessWidget {
  const MyKolabsSubTabs({
    required this.controller,
    required this.labels,
    super.key,
  });

  final TabController controller;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TabBar(
          controller: controller,
          labelStyle: KolabingTextStyles.button.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: KolabingTextStyles.button.copyWith(
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
          ),
          labelColor: c.onSurface,
          unselectedLabelColor: c.textTertiary,
          indicatorColor: c.primary,
          indicatorWeight: 3,
          dividerColor: Colors.transparent,
          tabs: labels.map((l) => Tab(text: l)).toList(),
        ),
        Divider(height: 1, thickness: 1, color: c.hairline),
      ],
    );
  }
}
