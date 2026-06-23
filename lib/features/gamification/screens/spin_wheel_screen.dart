import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../widgets/kolabing_button.dart';
import '../models/event_reward.dart';
import '../models/reward_claim.dart';
import '../providers/reward_provider.dart';

/// Screen for spinning the wheel after completing a challenge
class SpinWheelScreen extends ConsumerStatefulWidget {
  const SpinWheelScreen({
    super.key,
    required this.challengeCompletionId,
    required this.rewards,
  });

  final String challengeCompletionId;
  final List<EventReward> rewards;

  @override
  ConsumerState<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends ConsumerState<SpinWheelScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isSpinning = false;
  bool _hasSpun = false;
  SpinResult? _result;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _animation = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    if (_isSpinning || _hasSpun) return;

    setState(() {
      _isSpinning = true;
    });

    // Make API call
    final result = await ref
        .read(spinProvider.notifier)
        .spin(widget.challengeCompletionId);

    if (result == null) {
      setState(() {
        _isSpinning = false;
      });
      return;
    }

    // Calculate final rotation
    final random = math.Random();
    final baseRotations = 5 + random.nextInt(3); // 5-7 full rotations
    final finalAngle =
        baseRotations * 2 * math.pi + random.nextDouble() * 2 * math.pi;

    _animation = Tween<double>(
      begin: 0,
      end: finalAngle,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward().then((_) {
      setState(() {
        _isSpinning = false;
        _hasSpun = true;
        _result = result;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.onSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Spin to Win',
          style: KolabingTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: KolabingSpacing.xl),

            // Wheel
            Expanded(child: Center(child: _buildWheel())),

            // Spin button or result
            Padding(
              padding: const EdgeInsets.all(KolabingSpacing.lg),
              child: _hasSpun ? _buildResult() : _buildSpinButton(),
            ),

            const SizedBox(height: KolabingSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildWheel() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Wheel
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _animation.value,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: _getWheelColors(),
                    startAngle: 0,
                    endAngle: math.pi * 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.colors.primary.withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: _WheelPainter(
                    segments: widget.rewards.length + 1, // +1 for "Try Again"
                    rewards: widget.rewards,
                    colors: [
                      context.colors.primary,
                      context.colors.success,
                      context.colors.info,
                      context.colors.warning,
                      const Color(0xFF9B59B6),
                      const Color(0xFFE74C3C),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // Center circle
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: context.colors.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            _isSpinning ? LucideIcons.loader2 : LucideIcons.sparkles,
            size: 28,
            color: context.colors.onPrimary,
          ),
        ),

        // Pointer
        Positioned(
          top: 0,
          child: Container(
            width: 0,
            height: 0,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: context.colors.primary, width: 40),
                left: BorderSide(color: Colors.transparent, width: 15),
                right: BorderSide(color: Colors.transparent, width: 15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Color> _getWheelColors() {
    final colors = <Color>[];
    final baseColors = [
      context.colors.primary,
      context.colors.success,
      context.colors.info,
      context.colors.warning,
      const Color(0xFF9B59B6),
      const Color(0xFFE74C3C),
    ];

    for (int i = 0; i < widget.rewards.length + 1; i++) {
      colors.add(baseColors[i % baseColors.length]);
      colors.add(baseColors[i % baseColors.length]);
    }

    return colors;
  }

  Widget _buildSpinButton() {
    final spinState = ref.watch(spinProvider);

    return Column(
      children: [
        if (spinState.error != null) ...[
          Container(
            padding: const EdgeInsets.all(KolabingSpacing.md),
            decoration: BoxDecoration(
              color: context.colors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.alertCircle,
                  size: 20,
                  color: context.colors.error,
                ),
                const SizedBox(width: KolabingSpacing.sm),
                Text(
                  spinState.error!,
                  style: KolabingTextStyles.bodySmall.copyWith(
                    color: context.colors.error,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: KolabingSpacing.md),
        ],
        KolabingButton(
          label: 'SPIN THE WHEEL',
          onPressed: _isSpinning ? null : _spin,
          variant: KolabingButtonVariant.primary,
          isLoading: _isSpinning,
        ),
      ],
    );
  }

  Widget _buildResult() {
    final won = _result?.won ?? false;
    final reward = _result?.rewardClaim?.eventReward;

    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            won ? LucideIcons.partyPopper : LucideIcons.rotateCcw,
            size: 48,
            color: won
                ? context.colors.success
                : context.colors.onSurfaceVariant,
          ),
          const SizedBox(height: KolabingSpacing.md),
          Text(
            won ? 'Congratulations!' : 'Better luck next time!',
            style: KolabingTextStyles.bodyLarge.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: context.colors.onSurface,
            ),
          ),
          if (won && reward != null) ...[
            const SizedBox(height: KolabingSpacing.sm),
            Text(
              'You won: ${reward.name}',
              style: KolabingTextStyles.bodyMedium.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: KolabingSpacing.lg),
          KolabingButton(
            label: won ? 'View Reward' : 'Close',
            onPressed: () => Navigator.of(context).pop(_result),
            variant: KolabingButtonVariant.primary,
            size: KolabingButtonSize.compact,
          ),
        ],
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({
    required this.segments,
    required this.rewards,
    required this.colors,
  });

  final int segments;
  final List<EventReward> rewards;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = 2 * math.pi / segments;

    for (int i = 0; i < segments; i++) {
      final startAngle = i * segmentAngle - math.pi / 2;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        paint,
      );

      // Draw divider lines
      final linePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        center,
        Offset(
          center.dx + radius * math.cos(startAngle),
          center.dy + radius * math.sin(startAngle),
        ),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
