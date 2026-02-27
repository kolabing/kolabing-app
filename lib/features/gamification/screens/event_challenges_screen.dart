import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../models/challenge.dart';
import '../providers/challenge_provider.dart';
import '../widgets/challenge_card.dart';

/// Screen showing challenges for a specific event
class EventChallengesScreen extends ConsumerStatefulWidget {
  const EventChallengesScreen({
    super.key,
    required this.eventId,
    this.eventName,
    this.isOrganizer = false,
  });

  final String eventId;
  final String? eventName;
  final bool isOrganizer;

  @override
  ConsumerState<EventChallengesScreen> createState() =>
      _EventChallengesScreenState();
}

class _EventChallengesScreenState extends ConsumerState<EventChallengesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    ref.invalidate(eventChallengesProvider(widget.eventId));
  }

  @override
  Widget build(BuildContext context) {
    final challengesAsync = ref.watch(eventChallengesProvider(widget.eventId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? KolabingColors.darkBackground : KolabingColors.background,
      appBar: AppBar(
        backgroundColor:
            isDark ? KolabingColors.darkBackground : KolabingColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDark ? KolabingColors.textOnDark : KolabingColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.eventName ?? 'Challenges',
          style: GoogleFonts.rubik(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? KolabingColors.textOnDark : KolabingColors.textPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: KolabingColors.primary,
          labelColor: KolabingColors.primary,
          unselectedLabelColor: KolabingColors.textTertiary,
          labelStyle: GoogleFonts.openSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'All Challenges'),
            Tab(text: 'Custom'),
          ],
        ),
      ),
      body: challengesAsync.when(
        data: (response) => TabBarView(
          controller: _tabController,
          children: [
            // All challenges tab
            _ChallengesListView(
              challenges: response.challenges,
              isLoading: false,
              error: null,
              onRefresh: _onRefresh,
              onChallengeTap: _handleChallengeTap,
              emptyMessage: 'No challenges available for this event',
            ),

            // Custom challenges tab
            _ChallengesListView(
              challenges: response.customChallenges,
              isLoading: false,
              error: null,
              onRefresh: _onRefresh,
              onChallengeTap: _handleChallengeTap,
              emptyMessage: widget.isOrganizer
                  ? 'Create custom challenges for your event'
                  : 'No custom challenges yet',
            ),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: KolabingColors.primary),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.alertCircle,
                size: 48,
                color: KolabingColors.error.withValues(alpha: 0.7),
              ),
              const SizedBox(height: KolabingSpacing.md),
              Text(
                error.toString(),
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  color: KolabingColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KolabingSpacing.md),
              TextButton.icon(
                onPressed: _onRefresh,
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: widget.isOrganizer
          ? FloatingActionButton.extended(
              onPressed: _handleCreateChallenge,
              backgroundColor: KolabingColors.primary,
              foregroundColor: KolabingColors.onPrimary,
              icon: const Icon(LucideIcons.plus),
              label: Text(
                'New Challenge',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }

  void _handleChallengeTap(Challenge challenge) {
    if (widget.isOrganizer && challenge.isCustom) {
      // Organizer can edit custom challenges
      context.push(
        '/attendee/events/${widget.eventId}/challenges/${challenge.id}/edit',
      );
    } else {
      // Show challenge details / initiate challenge
      _showChallengeDetailsSheet(challenge);
    }
  }

  void _handleCreateChallenge() {
    context.push('/attendee/events/${widget.eventId}/challenges/create');
  }

  void _showChallengeDetailsSheet(Challenge challenge) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ChallengeDetailsSheet(
        challenge: challenge,
        eventId: widget.eventId,
      ),
    );
  }
}

class _ChallengesListView extends StatelessWidget {
  const _ChallengesListView({
    required this.challenges,
    required this.isLoading,
    required this.error,
    required this.onRefresh,
    required this.onChallengeTap,
    required this.emptyMessage,
  });

  final List<Challenge> challenges;
  final bool isLoading;
  final String? error;
  final Future<void> Function() onRefresh;
  final void Function(Challenge) onChallengeTap;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: KolabingColors.primary),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.alertCircle,
              size: 48,
              color: KolabingColors.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: KolabingSpacing.md),
            Text(
              error!,
              style: GoogleFonts.openSans(
                fontSize: 14,
                color: KolabingColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KolabingSpacing.md),
            TextButton.icon(
              onPressed: onRefresh,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (challenges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.target,
              size: 64,
              color: KolabingColors.textTertiary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: KolabingSpacing.md),
            Text(
              emptyMessage,
              style: GoogleFonts.openSans(
                fontSize: 14,
                color: KolabingColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: KolabingColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        itemCount: challenges.length,
        itemBuilder: (context, index) {
          final challenge = challenges[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
            child: ChallengeCard(
              challenge: challenge,
              onTap: () => onChallengeTap(challenge),
            ),
          );
        },
      ),
    );
  }
}

class _ChallengeDetailsSheet extends ConsumerWidget {
  const _ChallengeDetailsSheet({
    required this.challenge,
    required this.eventId,
  });

  final Challenge challenge;
  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? KolabingColors.darkSurface : KolabingColors.surface;
    final textColor =
        isDark ? KolabingColors.textOnDark : KolabingColors.textPrimary;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: KolabingColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(KolabingSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Challenge name
                Text(
                  challenge.name,
                  style: GoogleFonts.rubik(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: KolabingSpacing.sm),

                // Points and difficulty
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: KolabingColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.star,
                            size: 14,
                            color: KolabingColors.onPrimary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+${challenge.points} pts',
                            style: GoogleFonts.rubik(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: KolabingColors.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: KolabingSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(challenge.difficulty)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        challenge.difficulty.label,
                        style: GoogleFonts.openSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _getDifficultyColor(challenge.difficulty),
                        ),
                      ),
                    ),
                    if (challenge.isSystem) ...[
                      const SizedBox(width: KolabingSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: KolabingColors.info.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'System',
                          style: GoogleFonts.openSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: KolabingColors.info,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                if (challenge.description != null &&
                    challenge.description!.isNotEmpty) ...[
                  const SizedBox(height: KolabingSpacing.md),
                  Text(
                    challenge.description!,
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      color: KolabingColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],

                const SizedBox(height: KolabingSpacing.xl),

                // Initiate button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push(
                        '/attendee/events/$eventId/challenges/${challenge.id}/initiate',
                      );
                    },
                    icon: const Icon(LucideIcons.userPlus),
                    label: Text(
                      'START CHALLENGE',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KolabingColors.primary,
                      foregroundColor: KolabingColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: KolabingSpacing.md),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(ChallengeDifficulty difficulty) {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return const Color(0xFF155724);
      case ChallengeDifficulty.medium:
        return const Color(0xFF856404);
      case ChallengeDifficulty.hard:
        return const Color(0xFF721C24);
    }
  }
}
