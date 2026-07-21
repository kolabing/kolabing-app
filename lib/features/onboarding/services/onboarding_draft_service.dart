import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/onboarding_state.dart';

/// Persists the in-progress [OnboardingData] to local storage so the app
/// closing or crashing mid-onboarding doesn't lose everything the user
/// already entered (name, venue details, socials, etc.).
///
/// The draft is best-effort: if the device is low on storage or the write
/// fails for any reason, onboarding must still work normally in-memory —
/// persistence is a convenience, never a hard dependency.
class OnboardingDraftService {
  OnboardingDraftService._();
  static final OnboardingDraftService instance = OnboardingDraftService._();

  static const String _draftKey = 'onboarding_draft_v1';

  Future<void> save(OnboardingData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_draftKey, jsonEncode(data.toJson()));
    } catch (_) {
      // Best-effort — never let a persistence failure interrupt onboarding.
    }
  }

  /// Returns the saved draft, or null if there is none or it fails to parse
  /// (e.g. shipped a breaking schema change — better to drop a stale draft
  /// than crash onboarding on launch).
  Future<OnboardingData?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_draftKey);
      if (raw == null || raw.isEmpty) return null;
      return OnboardingData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftKey);
    } catch (_) {
      // No-op — nothing to clean up if this fails.
    }
  }
}
