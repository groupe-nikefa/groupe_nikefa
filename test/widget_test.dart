// Basic smoke test — verifies the app launches without crashing.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nikefa/main.dart';
import 'package:nikefa/core/hive/hive_registry.dart';

void main() {
  testWidgets('App launches and shows home screen', (tester) async {
    await dotenv.load(fileName: '.env');
    await Hive.initFlutter();
    await initHiveAdapters();

    await tester.pumpWidget(const ProviderScope(child: NikefaApp()));
    await tester.pumpAndSettle();

    expect(find.text('GROUPE'), findsWidgets);
    expect(find.text('NIKEFA'), findsWidgets);
  });
}
