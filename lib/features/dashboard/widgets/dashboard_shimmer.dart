import 'package:flutter/material.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';

/// Shimmer loading placeholder for the dashboard screen.
///
/// Displays animated placeholders mimicking the stats grid and upcoming list.
class DashboardShimmer extends StatefulWidget {
  const DashboardShimmer({super.key});

  @override
  State<DashboardShimmer> createState() => _DashboardShimmerState();
}

class _DashboardShimmerState extends State<DashboardShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (BuildContext context, Widget? _) {
        final opacity = 0.3 + (_animation.value * 0.4);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(KolabingSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header placeholder
              _ShimmerBox(width: 200, height: 24, opacity: opacity, isDark: isDark),
              const SizedBox(height: KolabingSpacing.xs),
              _ShimmerBox(width: 160, height: 16, opacity: opacity, isDark: isDark),
              const SizedBox(height: KolabingSpacing.lg),

              // Stats grid 2x2
              Row(
                children: [
                  Expanded(child: _ShimmerStatCard(opacity: opacity, isDark: isDark)),
                  const SizedBox(width: KolabingSpacing.sm),
                  Expanded(child: _ShimmerStatCard(opacity: opacity, isDark: isDark)),
                ],
              ),
              const SizedBox(height: KolabingSpacing.sm),
              Row(
                children: [
                  Expanded(child: _ShimmerStatCard(opacity: opacity, isDark: isDark)),
                  const SizedBox(width: KolabingSpacing.sm),
                  Expanded(child: _ShimmerStatCard(opacity: opacity, isDark: isDark)),
                ],
              ),
              const SizedBox(height: KolabingSpacing.lg),

              // Quick actions placeholder
              Row(
                children: [
                  Expanded(
                    child: _ShimmerBox(height: 48, opacity: opacity, isDark: isDark),
                  ),
                  const SizedBox(width: KolabingSpacing.sm),
                  Expanded(
                    child: _ShimmerBox(height: 48, opacity: opacity, isDark: isDark),
                  ),
                ],
              ),
              const SizedBox(height: KolabingSpacing.lg),

              // Section title
              _ShimmerBox(width: 180, height: 18, opacity: opacity, isDark: isDark),
              const SizedBox(height: KolabingSpacing.sm),

              // Upcoming items
              _ShimmerListItem(opacity: opacity, isDark: isDark),
              const SizedBox(height: KolabingSpacing.sm),
              _ShimmerListItem(opacity: opacity, isDark: isDark),
            ],
          ),
        );
      },
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    this.width,
    required this.height,
    required this.opacity,
    this.isDark = false,
  });

  final double? width;
  final double height;
  final double opacity;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark
            ? KolabingColors.darkBorder.withValues(alpha: opacity)
            : KolabingColors.border.withValues(alpha: opacity),
        borderRadius: KolabingRadius.borderRadiusSm,
      ),
    );
  }
}

class _ShimmerStatCard extends StatelessWidget {
  const _ShimmerStatCard({required this.opacity, this.isDark = false});

  final double opacity;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? KolabingColors.darkSurface : KolabingColors.surface,
        borderRadius: KolabingRadius.borderRadiusLg,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShimmerBox(width: 80, height: 12, opacity: opacity, isDark: isDark),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ShimmerBox(width: 40, height: 28, opacity: opacity, isDark: isDark),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? KolabingColors.darkBorder.withValues(alpha: opacity)
                      : KolabingColors.border.withValues(alpha: opacity),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShimmerListItem extends StatelessWidget {
  const _ShimmerListItem({required this.opacity, this.isDark = false});

  final double opacity;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? KolabingColors.darkSurface : KolabingColors.surface,
        borderRadius: KolabingRadius.borderRadiusMd,
        border: Border.all(
          color: isDark ? KolabingColors.darkBorder : KolabingColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? KolabingColors.darkBorder.withValues(alpha: opacity)
                  : KolabingColors.border.withValues(alpha: opacity),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: KolabingSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(width: 120, height: 14, opacity: opacity, isDark: isDark),
                const SizedBox(height: KolabingSpacing.xxs),
                _ShimmerBox(width: 180, height: 12, opacity: opacity, isDark: isDark),
                const SizedBox(height: KolabingSpacing.xs),
                _ShimmerBox(width: 80, height: 16, opacity: opacity, isDark: isDark),
              ],
            ),
          ),
          const SizedBox(width: KolabingSpacing.xs),
          _ShimmerBox(width: 60, height: 22, opacity: opacity, isDark: isDark),
        ],
      ),
    );
  }
}
