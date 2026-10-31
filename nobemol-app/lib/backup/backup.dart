import 'dart:convert';

import 'package:flutter/material.dart' show ThemeMode;

import 'package:nobemol/progress/database.dart';
import 'package:nobemol/progress/xp.dart';
import 'package:nobemol/reading/start_level.dart';
import 'package:nobemol/settings/settings.dart';

/// Version du format de fichier. Une sauvegarde reste sur le Drive de
/// l'élève : à chaque changement, augmenter ce numéro et garder la lecture
/// des formats d'avant (voir `doc/database.md`).
const backupFormat = 1;

/// Pourquoi un fichier ne s'importe pas.
enum BackupError {
  /// Pas une sauvegarde de Nobémol, ou un fichier abîmé.
  invalid,

  /// Écrite par une version plus récente de l'appli.
  tooNew,
}

class BackupException implements Exception {
  const BackupException(this.error, [this.detail]);

  final BackupError error;

  /// Ce qui ne va pas, pour le débogage.
  final String? detail;

  @override
  String toString() => 'BackupException(${error.name}, $detail)';
}

/// Toute la base, ligne par ligne.
class ProgressRows {
  const ProgressRows({
    this.sessions = const [],
    this.answers = const [],
    this.theory = const [],
    this.mastered = const [],
    this.achievements = const [],
  });

  /// Dans l'ordre des identifiants : la révision rejoue les réponses dans
  /// cet ordre.
  final List<SessionRow> sessions;
  final List<AnswerRow> answers;
  final List<TheoryRow> theory;
  final List<MasteredSkillRow> mastered;
  final List<AchievementRow> achievements;
}

/// Sauvegarde : la progression et les réglages, dans un fichier JSON.
///
/// Les identifiants de la base ne sont pas gardés : les réponses vont dans
/// leur session, dans l'ordre. Les dates sont en UTC.
class Backup {
  const Backup({
    required this.rows,
    required this.settings,
    required this.exportedAt,
  });

  /// Lit un fichier. Les réglages absents ou inconnus gardent la valeur de
  /// [current]. Lève une [BackupException].
  factory Backup.decode(String source, {required Settings current}) {
    try {
      final json = jsonDecode(source);
      if (json is! Map<String, Object?> || json['app'] != 'nobemol') {
        throw const BackupException(BackupError.invalid, 'app');
      }
      final format = _field<int>(json, 'format');
      if (format > backupFormat) {
        throw BackupException(BackupError.tooNew, 'format $format');
      }
      return Backup(
        rows: _readRows(_field<Map<String, Object?>>(json, 'progress')),
        settings: _readSettings(
          _field<Map<String, Object?>>(json, 'settings'),
          current,
        ),
        exportedAt: _date(json, 'exportedAt'),
      );
    } on BackupException {
      rethrow;
    } on FormatException catch (e) {
      throw BackupException(BackupError.invalid, e.message);
    }
  }

  final ProgressRows rows;

  /// Démarrage passé : une sauvegarde importée ne le repropose pas.
  final Settings settings;
  final DateTime exportedAt;

  /// Total d'XP, pour la confirmation avant d'importer.
  int get xp => rows.sessions.fold(0, (sum, session) => sum + session.xp);

  /// Nom de fichier proposé : `nobemol-2026-10-31.json`.
  String get fileName {
    final day = exportedAt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return 'nobemol-${day.year}-${two(day.month)}-${two(day.day)}.json';
  }

  String encode() {
    final answers = <int, List<AnswerRow>>{};
    for (final answer in rows.answers) {
      answers.putIfAbsent(answer.sessionId, () => []).add(answer);
    }
    return const JsonEncoder.withIndent(' ').convert({
      'app': 'nobemol',
      'format': backupFormat,
      'exportedAt': _iso(exportedAt),
      'settings': {
        'naming': settings.naming.name,
        'start': settings.start.name,
        'keyLabels': settings.keyLabels,
        'goal': settings.goal.name,
        'haptics': settings.haptics,
        'theme': settings.theme.name,
      },
      'progress': {
        'sessions': [
          for (final session in rows.sessions)
            {
              'lessonId': session.lessonId,
              'arcade': session.arcade,
              'score': session.score,
              'startedAt': _iso(session.startedAt),
              'finishedAt': _iso(session.finishedAt),
              'questions': session.questions,
              'correct': session.correct,
              'xp': session.xp,
              'bestCombo': session.bestCombo,
              'answers': [
                for (final answer in answers[session.id] ?? const <AnswerRow>[])
                  {
                    'expected': answer.expected,
                    'given': answer.given,
                    'elapsedMs': answer.elapsedMs,
                    'xp': answer.xp,
                    'card': answer.card,
                  },
              ],
            },
        ],
        'theory': [
          for (final theory in rows.theory)
            {
              'lessonId': theory.lessonId,
              'page': theory.page,
              'read': theory.read,
              'updatedAt': _iso(theory.updatedAt),
            },
        ],
        'mastered': [
          for (final skill in rows.mastered)
            {'skillId': skill.skillId, 'masteredAt': _iso(skill.masteredAt)},
        ],
        'achievements': [
          for (final achievement in rows.achievements)
            {
              'id': achievement.achievementId,
              'unlockedAt': _iso(achievement.unlockedAt),
            },
        ],
      },
    });
  }
}

ProgressRows _readRows(Map<String, Object?> json) {
  final sessions = <SessionRow>[];
  final answers = <AnswerRow>[];
  for (final session in _list(json, 'sessions')) {
    final id = sessions.length + 1;
    sessions.add(
      SessionRow(
        id: id,
        lessonId: _field<String?>(session, 'lessonId'),
        arcade: _field<String?>(session, 'arcade'),
        score: _field<int?>(session, 'score'),
        startedAt: _date(session, 'startedAt'),
        finishedAt: _date(session, 'finishedAt'),
        questions: _field<int>(session, 'questions'),
        correct: _field<int>(session, 'correct'),
        xp: _field<int>(session, 'xp'),
        bestCombo: _field<int>(session, 'bestCombo'),
      ),
    );
    for (final answer in _list(session, 'answers')) {
      answers.add(
        AnswerRow(
          id: answers.length + 1,
          sessionId: id,
          expected: _field<String>(answer, 'expected'),
          given: _field<String>(answer, 'given'),
          elapsedMs: _field<int>(answer, 'elapsedMs'),
          xp: _field<int>(answer, 'xp'),
          card: _field<String?>(answer, 'card'),
        ),
      );
    }
  }
  return ProgressRows(
    sessions: sessions,
    answers: answers,
    theory: [
      for (final theory in _list(json, 'theory'))
        TheoryRow(
          lessonId: _field<String>(theory, 'lessonId'),
          page: _field<int>(theory, 'page'),
          read: _field<bool>(theory, 'read'),
          updatedAt: _date(theory, 'updatedAt'),
        ),
    ],
    mastered: [
      for (final skill in _list(json, 'mastered'))
        MasteredSkillRow(
          skillId: _field<String>(skill, 'skillId'),
          masteredAt: _date(skill, 'masteredAt'),
        ),
    ],
    achievements: [
      for (final achievement in _list(json, 'achievements'))
        AchievementRow(
          achievementId: _field<String>(achievement, 'id'),
          unlockedAt: _date(achievement, 'unlockedAt'),
        ),
    ],
  );
}

Settings _readSettings(Map<String, Object?> json, Settings current) {
  T named<T extends Enum>(List<T> values, String key, T fallback) =>
      values.asNameMap()[json[key]] ?? fallback;
  bool flag(String key, bool fallback) => switch (json[key]) {
    final bool value => value,
    _ => fallback,
  };
  return current.copyWith(
    onboarded: true,
    naming: named(NoteNaming.values, 'naming', current.naming),
    start: named(StartLevel.values, 'start', current.start),
    keyLabels: flag('keyLabels', current.keyLabels),
    goal: named(DailyGoal.values, 'goal', current.goal),
    haptics: flag('haptics', current.haptics),
    theme: named(ThemeMode.values, 'theme', current.theme),
  );
}

T _field<T>(Map<String, Object?> json, String key) => switch (json[key]) {
  final T value => value,
  _ => throw FormatException('champ « $key »'),
};

/// En heure locale, comme les dates lues dans la base.
DateTime _date(Map<String, Object?> json, String key) =>
    DateTime.parse(_field<String>(json, key)).toLocal();

List<Map<String, Object?>> _list(Map<String, Object?> json, String key) => [
  for (final item in _field<List<Object?>>(json, key))
    if (item is Map<String, Object?>)
      item
    else
      throw FormatException('liste « $key »'),
];

String _iso(DateTime date) => date.toUtc().toIso8601String();
