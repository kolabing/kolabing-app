import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../gamification/models/challenge.dart';
import '../../opportunity/models/opportunity.dart';
import '../models/collaboration.dart';

/// Provider for collaboration detail - uses mock data for now
final collaborationDetailProvider =
    FutureProvider.family<Collaboration?, String>((ref, id) async {
  // Simulate network delay
  await Future<void>.delayed(const Duration(milliseconds: 800));
  return _mockCollaboration(id);
});

/// Provider for available challenges (system + custom)
final availableChallengesProvider =
    FutureProvider.family<List<Challenge>, String>(
        (ref, collaborationId) async {
  await Future<void>.delayed(const Duration(milliseconds: 500));
  return _mockChallenges;
});

/// Notifier for selected challenge IDs within a collaboration.
class ChallengeSelectionNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  void setInitial(List<String> ids) {
    state = ids;
  }

  void toggle(String challengeId) {
    if (state.contains(challengeId)) {
      state = state.where((id) => id != challengeId).toList();
    } else {
      state = [...state, challengeId];
    }
  }
}

final challengeSelectionProvider =
    NotifierProvider<ChallengeSelectionNotifier, List<String>>(
        ChallengeSelectionNotifier.new);

// =============================================================================
// Mock Data
// =============================================================================

Collaboration? _mockCollaboration(String id) {
  final now = DateTime.now();
  return Collaboration(
    id: id,
    status: CollaborationStatus.scheduled,
    scheduledDate: now.add(const Duration(days: 12)),
    scheduledTime: '14:00 - 18:00',
    businessPartner: const CollaborationPartner(
      id: 'biz-001',
      name: 'Nomad Coffee Roasters',
      profilePhoto: null,
      category: 'Food & Drink',
      city: 'Barcelona',
      userType: 'business',
    ),
    communityPartner: const CollaborationPartner(
      id: 'com-001',
      name: 'Barcelona Runners Club',
      profilePhoto: null,
      category: 'Sports & Fitness',
      city: 'Barcelona',
      userType: 'community',
    ),
    opportunity: null,
    contactMethods: const ContactMethods(
      whatsapp: '+34612345678',
      email: 'contact@nomadcoffee.com',
      instagram: '@nomadcoffee',
    ),
    businessOffer: const BusinessOffer(
      venue: true,
      foodDrink: true,
      socialMediaExposure: true,
      contentCreation: false,
      discount: DiscountOffer(enabled: true, percentage: 15),
      products: ['Specialty Coffee Tasting Kit'],
      other: 'Exclusive use of our rooftop terrace',
    ),
    communityDeliverables: const CommunityDeliverables(
      instagramPost: true,
      instagramStory: true,
      tiktokVideo: false,
      eventMention: true,
      attendeeCount: 50,
      other: 'Post-run group photo with branding',
    ),
    eventId: 'evt-001',
    qrCodeUrl: null,
    challenges: _mockChallenges,
    selectedChallengeIds: ['ch-001', 'ch-003'],
    createdAt: now.subtract(const Duration(days: 3)),
  );
}

final List<Challenge> _mockChallenges = [
  Challenge(
    id: 'ch-001',
    name: 'Check-in at Venue',
    description: 'Scan the QR code when you arrive at the event',
    difficulty: ChallengeDifficulty.easy,
    points: 5,
    isSystem: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Challenge(
    id: 'ch-002',
    name: 'Share on Instagram',
    description: 'Post a story or photo from the event and tag us',
    difficulty: ChallengeDifficulty.medium,
    points: 15,
    isSystem: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Challenge(
    id: 'ch-003',
    name: 'Try 3 Different Brews',
    description: 'Taste at least 3 different coffee brews during the event',
    difficulty: ChallengeDifficulty.medium,
    points: 20,
    isSystem: false,
    eventId: 'evt-001',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Challenge(
    id: 'ch-004',
    name: 'Group Photo Challenge',
    description: 'Take a group photo with at least 5 attendees',
    difficulty: ChallengeDifficulty.easy,
    points: 10,
    isSystem: false,
    eventId: 'evt-001',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Challenge(
    id: 'ch-005',
    name: 'Complete 5K Run',
    description: 'Finish the full 5K running route before the coffee tasting',
    difficulty: ChallengeDifficulty.hard,
    points: 30,
    isSystem: false,
    eventId: 'evt-001',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
];
