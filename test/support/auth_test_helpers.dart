import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/auth/providers/auth_provider.dart';

/// Marks [container]'s auth state as authenticated so providers guarded by
/// `AuthScopeGuard` load their data instead of clearing to the signed-out
/// (empty) state. Call this before first reading the guarded provider.
void authenticateContainer(
  ProviderContainer container, {
  String id = 'test-user-1',
  UserType userType = UserType.business,
}) {
  container.read(authProvider.notifier).state = AuthState(
    status: AuthStatus.authenticated,
    user: UserModel(id: id, email: '$id@example.com', userType: userType),
    token: 'test-token',
  );
}
