import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:italian_brainrot_app/app/providers.dart';
import 'package:italian_brainrot_app/core/strings.dart';
import 'package:italian_brainrot_app/data/user_data.dart';
import 'package:italian_brainrot_app/features/settings/credits_dialog.dart';
import 'package:italian_brainrot_app/features/settings/settings_dialog.dart';

void main() {
  setUp(() => S.forceJa = true);

  testWidgets('クレジット: CC BY の作者・題名・ライセンスが表示される', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CreditsDialog())));
    expect(find.textContaining('Bernard Gagnon'), findsOneWidget);
    expect(find.textContaining('Positano (Italy) 04'), findsOneWidget);
    expect(find.textContaining('CC BY 4.0'), findsOneWidget);
    expect(find.textContaining('Kenney'), findsOneWidget);
  });

  testWidgets('設定ダイアログから、クレジットが開く', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [userDataProvider.overrideWith((ref) => UserDataNotifier(UserDataStore(), UserData.initial(), 110))],
      child: const MaterialApp(home: Scaffold(body: SettingsDialog())),
    ));
    await tester.tap(find.byKey(const Key('creditsButton')));
    await tester.pump();
    expect(find.byType(CreditsDialog), findsOneWidget);
  });
}
