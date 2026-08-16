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

/// Single selection point for [MultiKolabRepository] — every Multi-Kolab
/// screen/provider reads through this, never constructs a repository
/// directly, so no screen ever has to know or check which implementation is
/// active.
final multiKolabRepositoryProvider = Provider<MultiKolabRepository>((ref) {
  if (_mockRequested && !kReleaseMode) {
    return MockMultiKolabRepository();
  }

  return ApiMultiKolabRepository(authService: ref.watch(authServiceProvider));
});
