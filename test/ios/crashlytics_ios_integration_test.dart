import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS Crashlytics upload-symbols build phase is configured', () {
    final projectFile = File('ios/Runner.xcodeproj/project.pbxproj');
    final projectContents = projectFile.readAsStringSync();

    expect(
      projectContents,
      contains('[firebase_crashlytics] Crashlytics Upload Symbols'),
    );
    expect(projectContents, contains('FirebaseCrashlytics/upload-symbols'));
    expect(projectContents, contains('--flutter-project'));
    expect(projectContents, contains('firebase_app_id_file.json'));
    expect(
      projectContents,
      contains(r'$(PROJECT_DIR)/firebase_app_id_file.json'),
    );
    expect(
      projectContents,
      contains(r'${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}'),
    );
  });

  test('iOS firebase app id file matches GoogleService-Info.plist', () {
    final appIdFile = File('ios/firebase_app_id_file.json');

    expect(appIdFile.existsSync(), isTrue);

    final appIdJson =
        json.decode(appIdFile.readAsStringSync()) as Map<String, dynamic>;
    final googleServiceInfo = File(
      'ios/Runner/GoogleService-Info.plist',
    ).readAsStringSync();

    expect(
      appIdJson['GOOGLE_APP_ID'],
      _plistStringValue(googleServiceInfo, 'GOOGLE_APP_ID'),
    );
    expect(
      appIdJson['FIREBASE_PROJECT_ID'],
      _plistStringValue(googleServiceInfo, 'PROJECT_ID'),
    );
    expect(
      appIdJson['GCM_SENDER_ID'],
      _plistStringValue(googleServiceInfo, 'GCM_SENDER_ID'),
    );
  });
}

String _plistStringValue(String plistContents, String key) {
  final escapedKey = RegExp.escape(key);
  final match = RegExp(
    '<key>$escapedKey</key>\\s*<string>([^<]+)</string>',
    multiLine: true,
  ).firstMatch(plistContents);

  if (match == null) {
    throw StateError('Missing plist value for $key');
  }

  return match.group(1)!;
}
