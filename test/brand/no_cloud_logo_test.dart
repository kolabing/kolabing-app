import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/widgets/navigation/kolabing_app_bar.dart';

/// The cloud lockup was retired for the K logomark (#234). These names are
/// the old assets and widget; none may come back into the app.
const _retired = [
  'logo_cloud',
  'logo_wordmark',
  'kolabing-wordmark',
  'kolabing-logomark',
  'KolabingLogo',
];

void main() {
  test('no source file references the retired cloud logo', () {
    final hits = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      for (final name in _retired) {
        if (source.contains(name)) hits.add('${entity.path}: $name');
      }
    }
    expect(hits, isEmpty);
  });

  testWidgets('the app bar shows the K tile, not the cloud wordmark', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(appBar: KolabingAppBar(actions: [])),
      ),
    );

    final mark = tester.widget<Image>(find.byKey(const Key('app-bar-k-mark')));
    expect(
      (mark.image as AssetImage).assetName,
      'assets/brand/kolabing-app-icon-k.png',
    );
    expect(find.text('KOLABING'), findsOneWidget);
  });
}
