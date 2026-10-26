import 'package:auno/core/theme/app_theme.dart';
import 'package:auno/presentation/screens/settings/about_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/url_launcher');
  final calls = <MethodCall>[];
  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.darkTheme, home: const AboutSettingsScreen()),
    );
    await tester.pumpAndSettle();
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    calls.clear();
  });
  testWidgets(
    'Developer social buttons launch the exact Instagram and GitHub profiles',
    (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return true;
          });
      await mount(tester);
      expect(find.text('Pengembang AUNO'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('@0ximam'), 200);
      await tester.tap(find.text('@0ximam'));
      await tester.pumpAndSettle();
      expect(
        (calls.last.arguments as Map)['url'],
        'https://www.instagram.com/0ximam/',
      );
      await tester.scrollUntilVisible(find.text('GitHub'), 100);
      await tester.tap(find.text('GitHub'));
      await tester.pumpAndSettle();
      expect((calls.last.arguments as Map)['url'], 'https://github.com/Imamgg');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'A refused external profile link falls back to the default browser',
    (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return calls.length > 1;
          });
      await mount(tester);
      await tester.scrollUntilVisible(find.text('@0ximam'), 200);
      await tester.tap(find.text('@0ximam'));
      await tester.pumpAndSettle();
      expect(calls, hasLength(2));
      expect(
        (calls[0].arguments as Map)['url'],
        (calls[1].arguments as Map)['url'],
      );
      expect(
        find.text('Profil belum dapat dibuka. Silakan coba lagi.'),
        findsNothing,
      );
    },
  );
  testWidgets('Unavailable app and browser handlers show a useful error', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => false);
    await mount(tester);
    await tester.scrollUntilVisible(find.text('@0ximam'), 200);
    await tester.tap(find.text('@0ximam'));
    await tester.pumpAndSettle();
    expect(
      find.text('Profil belum dapat dibuka. Silakan coba lagi.'),
      findsOneWidget,
    );
  });
}
