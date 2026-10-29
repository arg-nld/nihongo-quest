import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/progress_repository.dart';
import 'providers/providers.dart';
import 'ui/app.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        progressRepositoryProvider
            .overrideWith((ref) => SharedPreferencesProgressRepository(prefs)),
      ],
      child: const NihongoQuestApp(),
    ),
  );
}

class NihongoQuestApp extends StatelessWidget {
  const NihongoQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nihongo Quest',
      theme: AppTheme.light(),
      home: const AppShell(),
    );
  }
}
