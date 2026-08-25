import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../repositories/api_multi_kolab_repository.dart';
import '../repositories/mock_multi_kolab_repository.dart';
import '../repositories/multi_kolab_repository.dart';

/// Opt-in only, and hard-gated off in release builds regardless of the
/// define — `--dart-define=MULTI_KOLAB_USE_MOCK=true` has no effect on a
/// `flutter build`/release binary. This is the only way the mock
/// implementation can ever be selected.
const bool _mockRequested = bool.fromEnvironment('MULTI_KOLAB_USE_MOCK');

/// Whether Multi-Kolab data on screen is fixtures rather than the backend.
///
/// Exposed so the UI can SAY so. The mock has no auth awareness at all — its
/// viewer is the constant `MockMultiKolabRepository.mockViewerProfileId` — so it
/// hands the same "my events" to whoever is signed in. Signing in as a second
/// account therefore shows the first account's events, which reads exactly like
/// an ownership leak and was reported as one. It is not: the real path is
/// `GET /multi-kolab-events/me`, scoped server-side. Cross-account behaviour
/// cannot be tested against the mock, only against the backend.
const bool kMultiKolabMockData = _mockRequested && !kReleaseMode;

/// Single selection point for [MultiKolabRepository] — every Multi-Kolab
/// screen/provider reads through this, never constructs a repository
/// directly, so no screen ever has to know or check which implementation is
/// active.
final multiKolabRepositoryProvider = Provider<MultiKolabRepository>((ref) {
  if (kMultiKolabMockData) {
    return MockMultiKolabRepository();
  }

  return ApiMultiKolabRepository(authService: ref.watch(authServiceProvider));
});
