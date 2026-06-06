// Widget tests for the PasswordStrengthIndicator.
//
// Regression guard: the label below the strength bar MUST be the
// translated string (e.g. "Fort" / "قوية"), never the raw ARB key
// (e.g. "password_strength_strong"). See PasswordStrengthIndicator.label.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nikefa/core/widgets/password_strength_indicator.dart';
import 'package:nikefa/l10n/app_localizations.dart';

Widget _harness({required String password, Locale locale = const Locale('fr')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: PasswordStrengthIndicator(password: password),
    ),
  );
}

void main() {
  group('PasswordStrengthIndicator label', () {
    testWidgets('renders the localized strong label, not the raw key',
        (tester) async {
      await tester.pumpWidget(_harness(password: 'Abcdef1!'));

      // French translation of "password_strength_strong".
      expect(find.text('Fort'), findsOneWidget);

      // The raw ARB key must never leak into the UI.
      expect(find.text('password_strength_strong'), findsNothing);
    });

    testWidgets('renders the localized weak label', (tester) async {
      await tester.pumpWidget(_harness(password: 'abc'));

      expect(find.text('Faible'), findsOneWidget);
      expect(find.text('password_strength_weak'), findsNothing);
    });

    testWidgets('renders the localized medium label', (tester) async {
      await tester.pumpWidget(_harness(password: 'abcdef1'));

      expect(find.text('Moyen'), findsOneWidget);
      expect(find.text('password_strength_medium'), findsNothing);
    });

    testWidgets('renders the Arabic strong label when locale is ar',
        (tester) async {
      await tester.pumpWidget(
        _harness(password: 'Abcdef1!', locale: const Locale('ar')),
      );

      expect(find.text('قوية'), findsOneWidget);
      expect(find.text('password_strength_strong'), findsNothing);
    });
  });

  group('PasswordStrengthDisplay extension', () {
    test('l10nKey still returns the raw key for backward compatibility', () {
      expect(PasswordStrength.weak.l10nKey, 'password_strength_weak');
      expect(PasswordStrength.medium.l10nKey, 'password_strength_medium');
      expect(PasswordStrength.strong.l10nKey, 'password_strength_strong');
    });
  });
}
