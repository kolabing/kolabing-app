import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/moderation/providers/blocked_profiles_provider.dart';
import 'package:kolabing_app/features/moderation/services/moderation_service.dart';
import 'package:kolabing_app/features/moderation/widgets/report_sheet.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

class _RecordingModerationService implements ModerationService {
  ReportTargetType? targetType;
  String? targetId;
  ReportReason? reason;
  String? reportedProfileId;
  String? note;
  int reportCalls = 0;

  @override
  Future<List<String>> blockedProfileIds() async => const [];

  @override
  Future<void> block(String profileId) async {}

  @override
  Future<void> unblock(String profileId) async {}

  @override
  Future<void> report({
    required ReportTargetType targetType,
    required String targetId,
    required ReportReason reason,
    String? reportedProfileId,
    String? note,
  }) async {
    reportCalls++;
    this.targetType = targetType;
    this.targetId = targetId;
    this.reason = reason;
    this.reportedProfileId = reportedProfileId;
    this.note = note;
  }
}

void main() {
  testWidgets('ReportSheet submits a report with the selected reason', (
    tester,
  ) async {
    final service = _RecordingModerationService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [moderationServiceProvider.overrideWithValue(service)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ReportSheet.show(
                  context,
                  targetType: ReportTargetType.kolab,
                  targetId: 'kolab-1',
                  reportedProfileId: 'creator-1',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // The submit button is disabled until a reason is chosen.
    expect(service.reportCalls, 0);

    // Pick the "Spam" reason chip.
    await tester.tap(find.text('Spam'));
    await tester.pumpAndSettle();

    // Submit.
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();

    expect(service.reportCalls, 1);
    expect(service.targetType, ReportTargetType.kolab);
    expect(service.targetId, 'kolab-1');
    expect(service.reason, ReportReason.spam);
    expect(service.reportedProfileId, 'creator-1');
  });
}
