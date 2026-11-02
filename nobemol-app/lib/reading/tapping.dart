import 'dart:math';

import 'package:notation/core.dart';

// Rythme tapé : où tombent les attaques d'une phrase, et comment juger les
// touches de l'élève. Les temps sont des noires (chiffrage en x/4).

/// Écart toléré entre une touche et son attaque, dans un sens ou dans
/// l'autre. Fixe en millisecondes : la précision du geste ne dépend pas du
/// tempo.
const tapTolerance = Duration(milliseconds: 160);

/// Tempo des exercices, en noires par minute.
const minTempo = 40;
const maxTempo = 160;

/// Une attaque : une note ou un accord, avec les notes qui lui sont liées.
class Attack {
  const Attack({required this.chain, required this.beat});

  /// La note qui attaque, puis celles qui la prolongent (liaison).
  final List<EventRef> chain;

  /// Instant de l'attaque, en temps depuis le début de la phrase.
  final Fraction beat;

  EventRef get ref => chain.first;
}

/// Attaques de la première portée de [system], dans l'ordre. Un silence ne
/// se tape pas, une note liée à la précédente non plus : elle la prolonge.
List<Attack> attacksOf(System system) {
  final staff = system.staves.first;
  final attacks = <Attack>[];
  var beat = Fraction.zero;
  var tied = false;
  for (final (:measure, :event, :value) in staff.events) {
    final ref = EventRef(staff: 0, measure: measure, event: event);
    switch (value) {
      case Rest():
        break;
      case Note() when tied:
        break;
      case Note() || Chord():
        attacks.add(Attack(chain: system.tieChain(ref), beat: beat));
    }
    tied = value is Note && value.tiedToNext;
    beat = beat + value.duration * const Fraction(4);
  }
  return attacks;
}

/// Durée de la phrase en temps : toutes ses mesures.
Fraction beatsOfPhrase(System system) => system.staves.first.measures
    .map((measure) => measure.duration * const Fraction(4))
    .fold(Fraction.zero, (total, beats) => total + beats);

/// Durée d'un temps à [tempo] noires par minute.
Duration beatAt(int tempo) => Duration(microseconds: 60000000 ~/ tempo);

/// [beats] temps à [tempo].
Duration beatsAt(Fraction beats, int tempo) => Duration(
  microseconds:
      beats.numerator * beatAt(tempo).inMicroseconds ~/ beats.denominator,
);

/// Le plus court écart entre deux attaques de [system] à [tempo], `null`
/// s'il y a moins de deux attaques.
Duration? shortestGap(System system, int tempo) {
  final beats = attacksOf(system).map((attack) => attack.beat).toList();
  Duration? shortest;
  for (var i = 1; i < beats.length; i++) {
    final gap = beatsAt(beats[i] - beats[i - 1], tempo);
    if (shortest == null || gap < shortest) shortest = gap;
  }
  return shortest;
}

/// Clics d'un métronome : un par temps, le décompte puis la phrase. Le
/// premier temps de chaque mesure est marqué.
class ClickTrack {
  const ClickTrack({
    required this.tempo,
    required this.beatsPerMeasure,
    required this.beats,
  });

  /// Le métronome d'une phrase en x/4 : une mesure de décompte, puis les
  /// temps de la phrase.
  factory ClickTrack.forPhrase(System system, int tempo) {
    final beatsPerMeasure = system.staves.first.time!.beats;
    final phrase = beatsOfPhrase(system);
    return ClickTrack(
      tempo: tempo,
      beatsPerMeasure: beatsPerMeasure,
      // Une phrase en x/4 tient en un nombre entier de temps.
      beats: beatsPerMeasure + phrase.numerator ~/ phrase.denominator,
    );
  }

  /// Noires par minute.
  final int tempo;
  final int beatsPerMeasure;

  /// Nombre de clics, décompte compris.
  final int beats;

  Duration get beat => beatAt(tempo);

  /// Le décompte : une mesure.
  Duration get countIn => beat * beatsPerMeasure;

  /// Instant du clic [index].
  Duration click(int index) => beat * index;

  /// Vrai si le clic [index] ouvre une mesure.
  bool accented(int index) => index % beatsPerMeasure == 0;

  /// Fin du dernier temps.
  Duration get length => beat * beats;

  @override
  bool operator ==(Object other) =>
      other is ClickTrack &&
      other.tempo == tempo &&
      other.beatsPerMeasure == beatsPerMeasure &&
      other.beats == beats;

  @override
  int get hashCode => Object.hash(tempo, beatsPerMeasure, beats);
}

/// Place d'une touche par rapport à son attaque.
enum TapTiming { inTime, early, late, missed }

/// Bilan d'une phrase tapée, et réponse gardée pour la session : juste
/// ([inTime]), ou le défaut principal.
enum TapVerdict { inTime, early, late, missed, extra }

/// Les touches d'une phrase, jugées attaque par attaque.
class TapGrade {
  const TapGrade({
    required this.timings,
    required this.offsets,
    this.extra = 0,
  });

  /// Une place par attaque, dans l'ordre.
  final List<TapTiming> timings;

  /// Écart de la touche à son attaque (négatif : en avance), `null` pour
  /// une attaque sans touche.
  final List<Duration?> offsets;

  /// Touches qui ne tombent sur aucune attaque.
  final int extra;

  int count(TapTiming timing) => timings.where((t) => t == timing).length;

  /// Erreurs : notes pas en place (avance, retard, oubli) et touches en
  /// trop.
  int get faults => timings.length - count(TapTiming.inTime) + extra;

  /// Erreurs permises : une par tranche de 5 notes, une au moins (une sur
  /// 6 notes, deux sur 10).
  int get allowedFaults => max(1, timings.length ~/ 5);

  /// Juste si les erreurs ne dépassent pas [allowedFaults]. Sinon le défaut
  /// principal : une note oubliée, puis une touche en trop, puis l'avance
  /// ou le retard le plus fréquent.
  TapVerdict get verdict {
    if (faults <= allowedFaults) return TapVerdict.inTime;
    if (count(TapTiming.missed) > 0) return TapVerdict.missed;
    if (extra > 0) return TapVerdict.extra;
    final early = count(TapTiming.early);
    final late = count(TapTiming.late);
    return early > late ? TapVerdict.early : TapVerdict.late;
  }

  /// Écart moyen, en valeur absolue, des touches dans la tolérance.
  Duration? get meanInTime {
    final inTime = [
      for (final (index, timing) in timings.indexed)
        if (timing == TapTiming.inTime) offsets[index]!.abs(),
    ];
    if (inTime.isEmpty) return null;
    return inTime.fold(Duration.zero, (sum, d) => sum + d) ~/ inTime.length;
  }
}

/// Juge les touches [taps] face aux attaques attendues [expected] (mêmes
/// origines, dans l'ordre).
///
/// Touches et attaques sont **alignées dans l'ordre**, d'un seul coup, pour
/// le plus petit coût total : l'écart de chaque touche à son attaque, et un
/// demi-temps ([beat]) par note oubliée ou touche en trop. Une touche ne se
/// rapproche que d'une attaque à moins d'un demi-temps. Ainsi une touche en
/// retard reste à sa note au lieu de prendre celle d'après, et un double
/// appui est toujours compté en trop. Les touches plus d'un demi-temps
/// avant la première attaque (le décompte) ne comptent pas.
TapGrade gradeTaps({
  required List<Duration> expected,
  required List<Duration> taps,
  required Duration beat,
  Duration tolerance = tapTolerance,
}) {
  final reach = beat ~/ 2;
  final n = expected.length;
  if (n == 0) return const TapGrade(timings: [], offsets: []);
  final played = [
    for (final tap in taps)
      if (tap >= expected.first - reach) tap,
  ]..sort();
  final m = played.length;

  // cost[i][j] : plus petit coût pour les i premières attaques et les j
  // premières touches, en microsecondes.
  final penalty = reach.inMicroseconds;
  const unreachable = 1 << 62;
  final cost = [for (var i = 0; i <= n; i++) List.filled(m + 1, unreachable)];
  cost[0][0] = 0;
  for (var i = 0; i <= n; i++) {
    for (var j = 0; j <= m; j++) {
      final here = cost[i][j];
      if (here == unreachable) continue;
      // Note oubliée.
      if (i < n && here + penalty < cost[i + 1][j]) {
        cost[i + 1][j] = here + penalty;
      }
      // Touche en trop.
      if (j < m && here + penalty < cost[i][j + 1]) {
        cost[i][j + 1] = here + penalty;
      }
      // Touche à sa note.
      if (i < n && j < m) {
        final gap = (played[j] - expected[i]).abs();
        if (gap <= reach && here + gap.inMicroseconds < cost[i + 1][j + 1]) {
          cost[i + 1][j + 1] = here + gap.inMicroseconds;
        }
      }
    }
  }

  // Retour en arrière : quelle touche pour quelle note.
  final offsets = List<Duration?>.filled(n, null);
  var extra = 0;
  var i = n;
  var j = m;
  while (i > 0 || j > 0) {
    final here = cost[i][j];
    if (i > 0 && j > 0) {
      final offset = played[j - 1] - expected[i - 1];
      if (offset.abs() <= reach &&
          cost[i - 1][j - 1] + offset.abs().inMicroseconds == here) {
        offsets[i - 1] = offset;
        i--;
        j--;
        continue;
      }
    }
    if (j > 0 && cost[i][j - 1] + penalty == here) {
      extra++;
      j--;
    } else {
      i--;
    }
  }

  return TapGrade(
    timings: [
      for (final offset in offsets)
        switch (offset) {
          null => TapTiming.missed,
          _ when offset.abs() <= tolerance => TapTiming.inTime,
          _ when offset.isNegative => TapTiming.early,
          _ => TapTiming.late,
        },
    ],
    offsets: offsets,
    extra: extra,
  );
}

/// Instants des touches depuis le premier clic, à partir de ce que l'appli
/// reçoit : l'horodatage du système ([stamp], posé au contact du doigt, sur
/// sa propre horloge) et l'heure de réception ([received], sur l'horloge du
/// métronome).
///
/// La réception arrive un peu après le contact, d'un délai qui varie avec
/// la charge de l'appli. Les horodatages, eux, sont exacts entre eux : on
/// les recale sur l'horloge du métronome par le plus petit délai observé.
/// Sans horodatages utilisables (tous égaux, ou en désordre), la réception.
List<Duration> alignTaps(List<({Duration stamp, Duration received})> taps) {
  for (var i = 1; i < taps.length; i++) {
    if (taps[i].stamp <= taps[i - 1].stamp) {
      return [for (final tap in taps) tap.received];
    }
  }
  if (taps.isEmpty) return const [];
  final shift = taps
      .map((tap) => tap.received - tap.stamp)
      .reduce((a, b) => a < b ? a : b);
  return [for (final tap in taps) tap.stamp + shift];
}

/// Calage : clics et touches du test de calage.
const calibrationTrack = ClickTrack(tempo: 100, beatsPerMeasure: 4, beats: 16);

/// Touches à rapprocher de leur clic pour un calage fiable.
const calibrationMinTaps = 6;

/// Bornes du décalage mesuré : au-delà, ce n'est plus de la latence.
const maxTapLatency = Duration(milliseconds: 400);
const minTapLatency = Duration(milliseconds: -150);

/// Décalage entre un clic entendu et la touche qui l'accompagne : la
/// médiane des écarts, sur les clics après le décompte. `null` avec moins
/// de [calibrationMinTaps] touches près d'un clic.
Duration? calibrate(
  List<Duration> taps, {
  ClickTrack track = calibrationTrack,
}) {
  final half = track.beat ~/ 2;
  final offsets = <Duration>[];
  for (var i = track.beatsPerMeasure; i < track.beats; i++) {
    final click = track.click(i);
    final near = taps
        .map((tap) => tap - click)
        .where((offset) => offset >= -half && offset < half)
        .toList();
    if (near.isEmpty) continue;
    offsets.add(near.reduce((a, b) => a.abs() <= b.abs() ? a : b));
  }
  if (offsets.length < calibrationMinTaps) return null;
  offsets.sort();
  final median = offsets.length.isOdd
      ? offsets[offsets.length ~/ 2]
      : (offsets[offsets.length ~/ 2 - 1] + offsets[offsets.length ~/ 2]) ~/ 2;
  return Duration(
    microseconds: max(
      minTapLatency.inMicroseconds,
      min(maxTapLatency.inMicroseconds, median.inMicroseconds),
    ),
  );
}
