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
    this.trailing,
  });

  final TabController controller;
  final List<String> labels;

  /// Optional widget pinned to the right of the filter on the SAME row (e.g. a
  /// "N kolabs" count). Keeping the filter + count on one line avoids adding an
  /// extra row that pushes the list down.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final control = KolabingSegmentedControl<int>(
      style: KolabingSegmentedStyle.secondary,
      segments: [for (var i = 0; i < labels.length; i++) (i, labels[i])],
      selectedValue: controller.index,
      onChanged: controller.animateTo,
    );

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 6, 0, 10),
        // Control is centered; the optional count is pinned to the right edge
        // on the SAME row (a centered toggle, no extra row that shifts the page).
        child: SizedBox(
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              control,
              if (trailing != null)
                Align(alignment: Alignment.centerRight, child: trailing!),
            ],
          ),
        ),
      ),
    );
  }
}
