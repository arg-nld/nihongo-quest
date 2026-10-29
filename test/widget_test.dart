import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_quest/data/progress_repository.dart';
import 'package:nihongo_quest/main.dart';
import 'package:nihongo_quest/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('app shell renders the home screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        progressRepositoryProvider
            .overrideWith((ref) => SharedPreferencesProgressRepository(prefs)),
      ],
      child: const NihongoQuestApp(),
    ));
    await tester.pumpAndSettle();

    // The home tab shows the player name by default.
    expect(find.text('Traveler'), findsWidgets);
    // Bottom navigation offers the four tabs.
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('profile tab shows stats and settings', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        progressRepositoryProvider
            .overrideWith((ref) => SharedPreferencesProgressRepository(prefs)),
      ],
      child: const NihongoQuestApp(),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    // The profile screen is a scrollable list; the settings toggles live below
    // the fold, so scroll until they are built.
    await tester.scrollUntilVisible(find.text('Show romaji'), 300);
    await tester.pumpAndSettle();

    expect(find.text('Show romaji'), findsOneWidget);
    expect(find.text('Immediate feedback'), findsOneWidget);
  });
}
