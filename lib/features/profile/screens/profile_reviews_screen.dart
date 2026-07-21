import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/cards/kolabing_cards.dart';
import '../models/public_profile.dart';
import '../services/public_profile_service.dart';

class ProfileReviewsScreen extends StatefulWidget {
  const ProfileReviewsScreen({
    required this.profileId,
    this.profileName,
    super.key,
  });

  final String profileId;
  final String? profileName;

  @override
  State<ProfileReviewsScreen> createState() => _ProfileReviewsScreenState();
}

class _ProfileReviewsScreenState extends State<ProfileReviewsScreen> {
  final PublicProfileService _service = PublicProfileService();

  List<PublicProfileReview> _reviews = const <PublicProfileReview>[];
  int _page = 1;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _service.getProfileReviews(widget.profileId);
      if (!mounted) return;
      setState(() {
        _reviews = result.reviews;
        _page = result.currentPage;
        _hasMore = result.hasMore;
        _isLoading = false;
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _error = 'load_failed';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final result = await _service.getProfileReviews(
        widget.profileId,
        page: _page + 1,
      );
      if (!mounted) return;
      setState(() {
        _reviews = [..._reviews, ...result.reviews];
        _page = result.currentPage;
        _hasMore = result.hasMore;
        _isLoadingMore = false;
      });
    } on Exception {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = (widget.profileName?.trim().isNotEmpty ?? false)
        ? l10n.profileReviewsTitleNamed(widget.profileName!)
        : l10n.profileReviewsTitle;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        foregroundColor: context.colors.onSurface,
        elevation: 0,
        title: Text(
          title,
          style: KolabingTextStyles.bodyMedium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.colors.onSurface,
          ),
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.profileReviewsLoadError,
              style: KolabingTextStyles.bodyMedium.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: KolabingSpacing.sm),
            TextButton(onPressed: _loadInitial, child: Text(l10n.commonRetry)),
          ],
        ),
      );
    }

    if (_reviews.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(KolabingSpacing.xl),
          child: EmptyStateCard(
            icon: LucideIcons.star,
            title: l10n.profileReviewsEmpty,
            message: l10n.profileReviewsEmptyBody,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      itemCount: _reviews.length + 1,
      separatorBuilder: (context, index) =>
          const SizedBox(height: KolabingSpacing.sm),
      itemBuilder: (context, index) {
        if (index == _reviews.length) {
          if (!_hasMore) {
            return const SizedBox(height: KolabingSpacing.xl);
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.md),
            child: Center(
              child: OutlinedButton(
                onPressed: _isLoadingMore ? null : _loadMore,
                child: _isLoadingMore
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(AppLocalizations.of(context).profileReviewsLoadMore),
              ),
            ),
          );
        }
        return _ProfileReviewListCard(review: _reviews[index]);
      },
    );
  }
}

class _ProfileReviewListCard extends StatelessWidget {
  const _ProfileReviewListCard({required this.review});

  final PublicProfileReview review;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(KolabingSpacing.md),
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: KolabingRadius.borderRadiusLg,
      border: Border.all(color: context.colors.darkBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _ReviewAvatar(reviewer: review.reviewer),
            const SizedBox(width: KolabingSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.reviewer.displayName,
                    style: KolabingTextStyles.bodySmall.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.colors.onSurface,
                    ),
                  ),
                  Text(
                    _formatReviewDate(review.createdAt),
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: context.colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: KolabingSpacing.sm),
        Row(
          children: List.generate(
            5,
            (index) => Icon(
              index < review.rating
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              size: 18,
              color: context.colors.primary,
            ),
          ),
        ),
        if (review.hasBody) ...[
          const SizedBox(height: KolabingSpacing.sm),
          Text(
            review.body!,
            style: KolabingTextStyles.bodyMedium.copyWith(
              color: context.colors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ],
    ),
  );
}

class _ReviewAvatar extends StatelessWidget {
  const _ReviewAvatar({required this.reviewer});

  final PublicProfileReviewAuthor reviewer;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = reviewer.avatarUrl;
    if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
      return CircleAvatar(radius: 20, backgroundImage: NetworkImage(avatarUrl));
    }

    return CircleAvatar(
      radius: 20,
      backgroundColor: context.colors.primary.withValues(alpha: 0.12),
      child: Text(
        reviewer.initial,
        style: KolabingTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w700,
          color: context.colors.onSurface,
        ),
      ),
    );
  }
}

String _formatReviewDate(DateTime? date) {
  if (date == null) return '';

  const monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
}
