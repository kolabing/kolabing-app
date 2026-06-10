import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/models/auth_response.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/attendee_onboarding_state.dart';
import '../services/attendee_onboarding_service.dart';
import 'onboarding_provider.dart';

/// DI for [AttendeeOnboardingService].
final attendeeOnboardingServiceProvider = Provider<AttendeeOnboardingService>(
  (ref) => AttendeeOnboardingService(),
);

/// Holds the in-flight attendee onboarding data across the 4 step screens.
class AttendeeOnboardingNotifier extends Notifier<AttendeeOnboardingData> {
  @override
  AttendeeOnboardingData build() => const AttendeeOnboardingData();

  void updateName(String name) => state = state.copyWith(name: name);

  void updateHandle(String handle) =>
      state = state.copyWith(handle: handle.trim().toLowerCase());

  void updateCity(String cityId, String cityName) =>
      state = state.copyWith(cityId: cityId, cityName: cityName);

  void clearCity() => state = state.copyWith(clearCity: true);

  /// Toggle a community-type SLUG in the interests set.
  void toggleInterest(String slug) {
    final next = List<String>.from(state.interests);
    if (next.contains(slug)) {
      next.remove(slug);
    } else {
      next.add(slug);
    }
    state = state.copyWith(interests: next);
  }

  /// Toggle a community id chosen on the Join step.
  void toggleCommunity(String communityId) {
    final next = List<String>.from(state.communityIds);
    if (next.contains(communityId)) {
      next.remove(communityId);
    } else {
      next.add(communityId);
    }
    state = state.copyWith(communityIds: next);
  }

  Future<void> updatePhoto(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final fileName = file.path.split('/').last;
      state = state.copyWith(
        photoBase64: base64Encode(bytes),
        photoFileName: fileName,
        photoMimeType: _inferMimeType(fileName),
      );
    } on Exception catch (e) {
      debugPrint('Error encoding attendee photo: $e');
    }
  }

  void clearPhoto() => state = state.copyWith(clearPhoto: true);

  void goToStep(int step) => state = state.copyWith(currentStep: step);

  void reset() => state = const AttendeeOnboardingData();

  /// Submit `PUT /onboarding/attendee`, then refresh the global user.
  /// Returns an [OnboardingResult] mirroring the business/community flow so the
  /// screen can branch on success / validation error / feature-off.
  Future<OnboardingResult> submit() async {
    if (!state.isStep1Complete) {
      return const OnboardingResult(
        success: false,
        errorMessage: 'Please enter your name and handle',
      );
    }
    try {
      final authService = ref.read(authServiceProvider);
      final service = ref.read(attendeeOnboardingServiceProvider);
      final token = await authService.getToken();
      if (token == null || token.isEmpty) {
        return const OnboardingResult(
          success: false,
          errorMessage: 'Your session expired. Please sign in again.',
        );
      }
      await service.submit(token, state);
      await ref.read(authProvider.notifier).checkAuthStatus();
      return const OnboardingResult(success: true);
    } on OnboardingFeatureOffException {
      // Backend not deployed: treat as a no-op success so the user reaches home.
      return const OnboardingResult(success: true);
    } on ApiException catch (e) {
      return OnboardingResult(success: false, error: e.error);
    } on NetworkException catch (e) {
      return OnboardingResult(
        success: false,
        errorMessage: e.message,
        isNetworkError: true,
      );
    } on Exception catch (e) {
      debugPrint('Attendee onboarding submit error: $e');
      return const OnboardingResult(
        success: false,
        errorMessage: 'An unexpected error occurred',
      );
    }
  }

  String _inferMimeType(String fileNameOrPath) {
    final extension = fileNameOrPath.split('.').last.toLowerCase();
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }
}

final attendeeOnboardingProvider =
    NotifierProvider<AttendeeOnboardingNotifier, AttendeeOnboardingData>(
      AttendeeOnboardingNotifier.new,
    );
