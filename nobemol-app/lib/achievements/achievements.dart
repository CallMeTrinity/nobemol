import 'dart:math';

import 'package:nobemol/achievements/achievement.dart';
import 'package:nobemol/lessons/content.dart';
import 'package:nobemol/progress/progress.dart';
import 'package:nobemol/progress/xp.dart';

/// Un succès vu depuis la progression : où en est l'élève.
class AchievementProgress {
  const AchievementProgress({
    required this.achievement,
    required this.current,
    required this.target,
    required this.unlockedAt,
  });

  final Achievement achievement;

  /// Compte actuel, jamais au-delà de [target].
  final int current;
  final int target;

  /// Date du déblocage, `null` s'il n'est pas encore enregistré.
  final DateTime? unlockedAt;

  /// Débloqué : enregistré, ou atteint (après une mise à jour, avant la
  /// session suivante qui l'enregistre).
  bool get unlocked => unlockedAt != null || current >= target;
}

/// Les succès, calculés depuis la progression comme la maîtrise. Seul le
/// fait d'en avoir débloqué un est gardé : un succès reste acquis même si
/// sa condition change.
class AchievementList {
  AchievementList(this.content, this.progress);

  final Content content;
  final Progress progress;

  /// Tous les succès, dans l'ordre du fichier.
  late final List<AchievementProgress> all = [
    for (final achievement in content.achievements)
      _progress(achievement, progress.achievements[achievement.id]),
  ];

  int get unlocked => all.where((entry) => entry.unlocked).length;

  /// Succès atteints, pas encore enregistrés.
  Iterable<Achievement> get newlyReached => [
    for (final entry in all)
      if (entry.current >= entry.target && entry.unlockedAt == null)
        entry.achievement,
  ];

  AchievementProgress _progress(Achievement achievement, DateTime? at) {
    final (current, target) = _count(achievement);
    return AchievementProgress(
      achievement: achievement,
      current: min(current, target),
      target: target,
      unlockedAt: at,
    );
  }

  (int, int) _count(Achievement achievement) {
    final target = achievement.target;
    final sessions = progress.sessions;
    return switch (achievement.kind) {
      AchievementKind.lessons => (progress.bestScores.length, target),
      AchievementKind.perfect => (
        sessions
            .where(
              (session) =>
                  session.lessonId != null &&
                  session.questions > 0 &&
                  session.correct == session.questions,
            )
            .length,
        target,
      ),
      AchievementKind.answers => (
        sessions.fold(0, (sum, session) => sum + session.correct),
        target,
      ),
      AchievementKind.combo => (
        sessions.fold(0, (best, session) => max(best, session.bestCombo)),
        target,
      ),
      AchievementKind.streak => (progress.bestStreak, target),
      AchievementKind.level => (Level.of(progress.xp).number, target),
      AchievementKind.mastered => (progress.mastered.length, target),
      AchievementKind.branch => _branch(achievement.branch!),
      AchievementKind.chrono ||
      AchievementKind.endless ||
      AchievementKind.survival => (_record(achievement.kind.name), target),
      AchievementKind.acquired => (
        progress.cards.values.where((card) => card.acquired).length,
        target,
      ),
    };
  }

  /// Compétences de [branch] qui ont des leçons : maîtrisées, en tout.
  (int, int) _branch(String branch) {
    final skills = [
      for (final skill in content.skills)
        if (skill.id.split('.').first == branch &&
            content.lessons.any((lesson) => lesson.skills.contains(skill.id)))
          skill.id,
    ];
    return (skills.where(progress.mastered.contains).length, skills.length);
  }

  /// Meilleur score de [mode], toutes clés (`chrono:treble`, `survival`).
  int _record(String mode) => progress.records.entries
      .where((record) => record.key.split(':').first == mode)
      .fold(0, (best, record) => max(best, record.value));
}
