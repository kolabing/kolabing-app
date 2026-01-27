import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../models/collab_request.dart';
import '../providers/explore_provider.dart';

/// Detail screen for a community offer/opportunity
///
/// Shows full details of a collaboration request including:
/// - Community info header
/// - Event details
/// - Photos gallery
/// - Previous collaborations
/// - Apply action
class CommunityOfferDetailScreen extends ConsumerStatefulWidget {
  const CommunityOfferDetailScreen({
    required this.offerId,
    this.offer,
    super.key,
  });

  /// The ID of the offer to display
  final String offerId;

  /// Optional pre-loaded offer data (for navigation optimization)
  final CollabRequest? offer;

  @override
  ConsumerState<CommunityOfferDetailScreen> createState() =>
      _CommunityOfferDetailScreenState();
}

class _CommunityOfferDetailScreenState
    extends ConsumerState<CommunityOfferDetailScreen> {
  late CollabRequest? _offer;
  bool _isLoading = false;
  String? _error;
  int _currentPhotoIndex = 0;

  // Mock photos for demonstration (API endpoint needed)
  final List<String> _mockPhotos = [];

  // Mock previous events (API endpoint needed)
  final List<_PreviousEvent> _mockPreviousEvents = [
    _PreviousEvent(
      id: '1',
      title: 'Summer Music Festival 2025',
      date: DateTime(2025, 7, 15),
      attendees: 2500,
      imageUrl: null,
    ),
    _PreviousEvent(
      id: '2',
      title: 'Food & Wine Week',
      date: DateTime(2025, 9, 10),
      attendees: 1800,
      imageUrl: null,
    ),
    _PreviousEvent(
      id: '3',
      title: 'Tech Networking Night',
      date: DateTime(2025, 11, 20),
      attendees: 350,
      imageUrl: null,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _offer = widget.offer;
    if (_offer == null) {
      _loadOffer();
    }
  }

  Future<void> _loadOffer() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Try to find in cached list first
      final asyncValue = ref.read(collabRequestsProvider);
      if (asyncValue.hasValue) {
        final requests = asyncValue.value;
        if (requests != null) {
          final found = requests.where((CollabRequest r) => r.id == widget.offerId).firstOrNull;
          if (found != null) {
            setState(() {
              _offer = found;
              _isLoading = false;
            });
            return;
          }
        }
      }

      // TODO(developer): Implement API call for single offer detail
      // final offer = await exploreService.getOfferDetail(widget.offerId);

      setState(() {
        _isLoading = false;
        _error = 'Offer not found';
      });
    } on Exception catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _handleApply() {
    if (_offer == null) return;

    // TODO(developer): Navigate to application flow
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applying to: ${_offer!.title}'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: KolabingColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null || _offer == null) {
      return _buildErrorState();
    }

    return Scaffold(
      backgroundColor: KolabingColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // App bar with back button
              SliverAppBar(
                backgroundColor: KolabingColors.primary,
                expandedHeight: 200,
                pinned: true,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.arrowLeft,
                      color: KolabingColors.textPrimary,
                      size: 20,
                    ),
                  ),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeroHeader(),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event Details Card
                      _buildDetailsCard(),

                      // Photos Gallery
                      if (_mockPhotos.isNotEmpty) _buildPhotosGallery(),

                      // Previous Events
                      _buildPreviousEventsSection(),

                      // Community Profile Section
                      _buildCommunitySection(),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Fixed Apply Button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildApplyButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              KolabingColors.primary,
              KolabingColors.primary.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              KolabingSpacing.md,
              60,
              KolabingSpacing.md,
              KolabingSpacing.md,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Community avatar and name
                Row(
                  children: [
                    _CommunityAvatar(
                      avatarUrl: _offer!.communityAvatarUrl,
                      initial: _offer!.communityInitial,
                      size: 56,
                    ),
                    const SizedBox(width: KolabingSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _offer!.communityName,
                            style: GoogleFonts.rubik(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: KolabingColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '@${_offer!.communityUsername}',
                            style: GoogleFonts.openSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: KolabingColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    _StatusBadge(status: _offer!.status),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildDetailsCard() => Container(
        margin: const EdgeInsets.all(KolabingSpacing.md),
        padding: const EdgeInsets.all(KolabingSpacing.md),
        decoration: BoxDecoration(
          color: KolabingColors.surface,
          borderRadius: KolabingRadius.borderRadiusLg,
          boxShadow: [
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
            // Title
            Text(
              _offer!.title,
              style: GoogleFonts.rubik(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: KolabingColors.textPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: KolabingSpacing.sm),

            // Type badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: KolabingSpacing.sm,
                vertical: KolabingSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: KolabingColors.primary.withValues(alpha: 0.15),
                borderRadius: KolabingRadius.borderRadiusRound,
              ),
              child: Text(
                _offer!.collabType.displayName.toUpperCase(),
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: KolabingColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: KolabingSpacing.md),

            // Description
            Text(
              _offer!.description,
              style: GoogleFonts.openSans(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: KolabingColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: KolabingSpacing.md),

            // Info rows
            _buildInfoRow(
              icon: LucideIcons.mapPin,
              label: 'Location',
              value: _offer!.location,
            ),
            const SizedBox(height: KolabingSpacing.sm),
            _buildInfoRow(
              icon: LucideIcons.calendar,
              label: 'Date',
              value: _formatDateRange(),
            ),

            // Reward section
            if (_offer!.hasReward) ...[
              const SizedBox(height: KolabingSpacing.md),
              Container(
                padding: const EdgeInsets.all(KolabingSpacing.sm),
                decoration: BoxDecoration(
                  color: KolabingColors.success.withValues(alpha: 0.1),
                  borderRadius: KolabingRadius.borderRadiusMd,
                  border: Border.all(
                    color: KolabingColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: KolabingColors.success.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.gift,
                        size: 20,
                        color: KolabingColors.activeText,
                      ),
                    ),
                    const SizedBox(width: KolabingSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reward Included',
                            style: GoogleFonts.openSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: KolabingColors.activeText,
                            ),
                          ),
                          if (_offer!.rewardDescription != null)
                            Text(
                              _offer!.rewardDescription!,
                              style: GoogleFonts.openSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: KolabingColors.activeText,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) =>
      Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: KolabingColors.textTertiary,
          ),
          const SizedBox(width: KolabingSpacing.xs),
          Text(
            '$label: ',
            style: GoogleFonts.openSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: KolabingColors.textTertiary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.openSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: KolabingColors.textPrimary,
              ),
            ),
          ),
        ],
      );

  Widget _buildPhotosGallery() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.md),
            child: Text(
              'PHOTOS',
              style: GoogleFonts.rubik(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: KolabingColors.textPrimary,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: KolabingSpacing.sm),
          SizedBox(
            height: 200,
            child: PageView.builder(
              itemCount: _mockPhotos.length,
              onPageChanged: (index) {
                setState(() => _currentPhotoIndex = index);
              },
              itemBuilder: (context, index) => Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: KolabingSpacing.md),
                decoration: BoxDecoration(
                  borderRadius: KolabingRadius.borderRadiusLg,
                  image: DecorationImage(
                    image: NetworkImage(_mockPhotos[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: KolabingSpacing.sm),
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _mockPhotos.length,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == _currentPhotoIndex
                      ? KolabingColors.primary
                      : KolabingColors.border,
                ),
              ),
            ),
          ),
          const SizedBox(height: KolabingSpacing.md),
        ],
      );

  Widget _buildPreviousEventsSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PREVIOUS EVENTS',
                  style: GoogleFonts.rubik(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: KolabingColors.textPrimary,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  '${_mockPreviousEvents.length} events',
                  style: GoogleFonts.openSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: KolabingColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: KolabingSpacing.sm),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: KolabingSpacing.md),
              itemCount: _mockPreviousEvents.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: KolabingSpacing.sm),
              itemBuilder: (context, index) =>
                  _PreviousEventCard(event: _mockPreviousEvents[index]),
            ),
          ),
          const SizedBox(height: KolabingSpacing.md),
        ],
      );

  Widget _buildCommunitySection() => Container(
        margin: const EdgeInsets.symmetric(horizontal: KolabingSpacing.md),
        padding: const EdgeInsets.all(KolabingSpacing.md),
        decoration: BoxDecoration(
          color: KolabingColors.surface,
          borderRadius: KolabingRadius.borderRadiusLg,
          boxShadow: [
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
            Text(
              'ABOUT THE COMMUNITY',
              style: GoogleFonts.rubik(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: KolabingColors.textPrimary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: KolabingSpacing.md),
            Row(
              children: [
                _CommunityAvatar(
                  avatarUrl: _offer!.communityAvatarUrl,
                  initial: _offer!.communityInitial,
                  size: 48,
                ),
                const SizedBox(width: KolabingSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _offer!.communityName,
                        style: GoogleFonts.openSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: KolabingColors.textPrimary,
                        ),
                      ),
                      Text(
                        '@${_offer!.communityUsername}',
                        style: GoogleFonts.openSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: KolabingColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: KolabingSpacing.sm),
            // Stats row (placeholder - needs API)
            Row(
              children: [
                _buildStatItem('Events', '${_mockPreviousEvents.length}'),
                const SizedBox(width: KolabingSpacing.lg),
                _buildStatItem('Followers', '15K+'),
                const SizedBox(width: KolabingSpacing.lg),
                _buildStatItem('Rating', '4.8'),
              ],
            ),
          ],
        ),
      );

  Widget _buildStatItem(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.rubik(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: KolabingColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.openSans(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: KolabingColors.textTertiary,
            ),
          ),
        ],
      );

  Widget _buildApplyButton() => Container(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        decoration: BoxDecoration(
          color: KolabingColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _handleApply,
              style: ElevatedButton.styleFrom(
                backgroundColor: KolabingColors.primary,
                foregroundColor: KolabingColors.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: KolabingRadius.borderRadiusMd,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.send, size: 18),
                  const SizedBox(width: KolabingSpacing.xs),
                  Text(
                    'APPLY NOW',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildLoadingState() => Scaffold(
        backgroundColor: KolabingColors.background,
        appBar: AppBar(
          backgroundColor: KolabingColors.primary,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => context.pop(),
          ),
        ),
        body: Shimmer.fromColors(
          baseColor: KolabingColors.surfaceVariant,
          highlightColor: KolabingColors.surface,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(KolabingSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 24,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: KolabingRadius.borderRadiusSm,
                  ),
                ),
                const SizedBox(height: KolabingSpacing.md),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: KolabingRadius.borderRadiusLg,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildErrorState() => Scaffold(
        backgroundColor: KolabingColors.background,
        appBar: AppBar(
          backgroundColor: KolabingColors.primary,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Offer Details',
            style: GoogleFonts.rubik(
              fontWeight: FontWeight.w600,
              color: KolabingColors.textPrimary,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(KolabingSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    color: KolabingColors.errorBg,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: Icon(
                      LucideIcons.alertCircle,
                      size: 36,
                      color: KolabingColors.error,
                    ),
                  ),
                ),
                const SizedBox(height: KolabingSpacing.lg),
                Text(
                  'Offer Not Found',
                  style: GoogleFonts.rubik(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: KolabingColors.textPrimary,
                  ),
                ),
                const SizedBox(height: KolabingSpacing.xs),
                Text(
                  _error ?? 'Unable to load offer details',
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    color: KolabingColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: KolabingSpacing.lg),
                ElevatedButton.icon(
                  onPressed: _loadOffer,
                  icon: const Icon(LucideIcons.rotateCcw, size: 16),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KolabingColors.primary,
                    foregroundColor: KolabingColors.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  String _formatDateRange() {
    final dateFormat = DateFormat('MMM d, yyyy');
    if (_offer!.endDate != null) {
      return '${dateFormat.format(_offer!.startDate)} - ${dateFormat.format(_offer!.endDate!)}';
    }
    return 'Starting ${dateFormat.format(_offer!.startDate)}';
  }
}

/// Community avatar widget
class _CommunityAvatar extends StatelessWidget {
  const _CommunityAvatar({
    required this.avatarUrl,
    required this.initial,
    this.size = 48,
  });

  final String? avatarUrl;
  final String initial;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: KolabingColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: avatarUrl != null
            ? ClipOval(
                child: Image.network(
                  avatarUrl!,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildInitial(),
                ),
              )
            : _buildInitial(),
      );

  Widget _buildInitial() => Center(
        child: Text(
          initial,
          style: GoogleFonts.rubik(
            fontSize: size * 0.4,
            fontWeight: FontWeight.w600,
            color: KolabingColors.textPrimary,
          ),
        ),
      );
}

/// Status badge widget
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final CollabStatus status;

  @override
  Widget build(BuildContext context) {
    final (backgroundColor, textColor) = switch (status) {
      CollabStatus.active => (KolabingColors.activeBg, KolabingColors.activeText),
      CollabStatus.published =>
        (KolabingColors.pendingBg, KolabingColors.pendingText),
      CollabStatus.closed =>
        (KolabingColors.completedBg, KolabingColors.completedText),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.sm,
        vertical: KolabingSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: KolabingRadius.borderRadiusRound,
      ),
      child: Text(
        status.displayName.toUpperCase(),
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Previous event model (placeholder until API)
class _PreviousEvent {
  const _PreviousEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.attendees,
    this.imageUrl,
  });

  final String id;
  final String title;
  final DateTime date;
  final int attendees;
  final String? imageUrl;
}

/// Previous event card widget
class _PreviousEventCard extends StatelessWidget {
  const _PreviousEventCard({required this.event});

  final _PreviousEvent event;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM yyyy');

    return Container(
      width: 160,
      padding: const EdgeInsets.all(KolabingSpacing.sm),
      decoration: BoxDecoration(
        color: KolabingColors.surface,
        borderRadius: KolabingRadius.borderRadiusMd,
        border: Border.all(color: KolabingColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event image or placeholder
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: KolabingColors.primary.withValues(alpha: 0.1),
              borderRadius: KolabingRadius.borderRadiusSm,
            ),
            child: event.imageUrl != null
                ? ClipRRect(
                    borderRadius: KolabingRadius.borderRadiusSm,
                    child: Image.network(
                      event.imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  )
                : Center(
                    child: Icon(
                      LucideIcons.calendar,
                      size: 24,
                      color: KolabingColors.primary.withValues(alpha: 0.5),
                    ),
                  ),
          ),
          const SizedBox(height: KolabingSpacing.xs),

          // Title
          Text(
            event.title,
            style: GoogleFonts.openSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: KolabingColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),

          // Date and attendees
          Row(
            children: [
              Icon(
                LucideIcons.calendar,
                size: 12,
                color: KolabingColors.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                dateFormat.format(event.date),
                style: GoogleFonts.openSans(
                  fontSize: 11,
                  color: KolabingColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                LucideIcons.users,
                size: 12,
                color: KolabingColors.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                '${event.attendees} attendees',
                style: GoogleFonts.openSans(
                  fontSize: 11,
                  color: KolabingColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
