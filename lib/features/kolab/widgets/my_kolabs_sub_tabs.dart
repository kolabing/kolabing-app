// lib/features/kolab/widgets/my_kolabs_sub_tabs.dart
import 'package:flutter/material.dart';

import '../../../widgets/kolabing_segmented_control.dart';

/// Shared secondary segmented-control row for all My Kolabs sections.
///
/// Use for Published/Draft (Offers) and Sent/Received (Requests). Wraps
/// [KolabingSegmentedControl] (secondary style) while keeping the existing
/// `TabController` + `labels` API so callers don't need to change their
/// wiring.
class MyKolabsSubTabs extends StatelessWidget {
  const MyKolabsSubTabs({
    required this.controller,
    required this.labels,
    super.key,
  });

  final TabController controller;
  final List<String> labels;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 16),
      child: KolabingSegmentedControl<int>(
        style: KolabingSegmentedStyle.secondary,
        segments: [for (var i = 0; i < labels.length; i++) (i, labels[i])],
        selectedValue: controller.index,
        onChanged: controller.animateTo,
      ),
    ),
  );
}
