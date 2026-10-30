import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nobemol/lessons/content_provider.dart';
import 'package:nobemol/licenses.dart';
import 'package:nobemol/progress/xp.dart';
import 'package:nobemol/reading/start_level.dart';
import 'package:nobemol/settings/settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('réglages', () {
    test('absents : valeurs par défaut, démarrage à faire', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsStore(await SharedPreferences.getInstance())
          .load();
      expect(settings.onboarded, isFalse);
      expect(settings.naming, NoteNaming.solfege);
      expect(settings.start, StartLevel.beginner);
      expect(settings.keyLabels, isTrue);
      expect(settings.goal, DailyGoal.five);
      expect(settings.haptics, isTrue);
      expect(settings.theme, ThemeMode.system);
    });

    test('écrits puis relus', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SettingsStore(await SharedPreferences.getInstance());
      await store.save(
        const Settings(
          onboarded: true,
          naming: NoteNaming.letters,
          start: StartLevel.readsBoth,
          keyLabels: false,
          goal: DailyGoal.fifteen,
          haptics: false,
          theme: ThemeMode.dark,
        ),
      );
      final settings = store.load();
      expect(settings.onboarded, isTrue);
      expect(settings.naming, NoteNaming.letters);
      expect(settings.start, StartLevel.readsBoth);
      expect(settings.keyLabels, isFalse);
      expect(settings.goal, DailyGoal.fifteen);
      expect(settings.haptics, isFalse);
      expect(settings.theme, ThemeMode.dark);
    });

    test(
      'valeur inconnue (réglage d’une autre version) : par défaut',
      () async {
        SharedPreferences.setMockInitialValues({
          'naming': 'german',
          'goal': 'thirty',
        });
        final settings = SettingsStore(await SharedPreferences.getInstance())
            .load();
        expect(settings.naming, NoteNaming.solfege);
        expect(settings.goal, DailyGoal.five);
      },
    );
  });

  test(
    'points de départ : compétences de l’arbre, prérequis compris',
    () async {
      final content = await loadContent(rootBundle);
      final skills = {for (final skill in content.skills) skill.id: skill};
      for (final level in StartLevel.values) {
        for (final id in level.acquired) {
          expect(skills, contains(id), reason: '${level.name} : $id');
          for (final required in skills[id]!.requires) {
            expect(level.acquired, contains(required), reason: id);
          }
        }
      }
    },
  );

  test('licences des polices dans À propos', () async {
    registerFontLicenses(rootBundle);
    final packages = <String>{};
    await for (final license in LicenseRegistry.licenses) {
      packages.addAll(license.packages);
    }
    expect(
      packages,
      containsAll([
        'Bravura',
        'Edwin',
        'Bricolage Grotesque',
        'Instrument Sans',
        'DM Mono',
      ]),
    );
  });
}
