import 'package:meta/meta.dart';
import 'package:notation/src/model/clef.dart';
import 'package:notation/src/model/fraction.dart';
import 'package:notation/src/model/key_signature.dart';
import 'package:notation/src/model/pitch.dart';
import 'package:notation/src/model/time_signature.dart';

/// Figure de note ou de silence, sans le point.
enum NoteValue {
  /// Ronde.
  whole(Fraction(1)),

  /// Blanche.
  half(Fraction(1, 2)),

  /// Noire.
  quarter(Fraction(1, 4)),

  /// Croche.
  eighth(Fraction(1, 8)),

  /// Double croche.
  sixteenth(Fraction(1, 16));

  new(this.duration);

  /// Durée, en rondes.
  final Fraction duration;

  /// Nombre de crochets d'une note isolée, ou de ligatures dans un groupe :
  /// 0 jusqu'à la noire.
  int get flags => switch (this) {
    eighth => 1,
    sixteenth => 2,
    _ => 0,
  };
}

/// Ce qui occupe du temps dans une mesure : une note ou un silence. Les
/// accords viendront s'ajouter.
sealed class Event {
  const new({required this.value, required this.dotted});

  /// Figure.
  final NoteValue value;

  /// Vrai si la figure est pointée : sa durée est multipliée par 3/2.
  final bool dotted;

  /// Durée, en rondes.
  Fraction get duration =>
      dotted ? value.duration * const Fraction(3, 2) : value.duration;
}

/// Note : une hauteur et une figure.
class Note extends Event {
  /// Crée une note, ronde par défaut.
  const new(
    this.pitch, {
    super.value = NoteValue.whole,
    super.dotted = false,
    this.tiedToNext = false,
    this.beamedToNext = false,
  });

  /// Hauteur.
  final Pitch pitch;

  /// Vrai si une liaison de prolongation la relie à la note suivante de la
  /// portée, de même hauteur.
  final bool tiedToNext;

  /// Vrai si une ligature la relie à la note suivante de la mesure. Seules
  /// les croches et les valeurs plus courtes en ont une.
  final bool beamedToNext;
}

/// Silence : une figure, sans hauteur.
class Rest extends Event {
  /// Crée un silence, une pause par défaut.
  const new({super.value = NoteValue.whole, super.dotted = false});
}

/// Barre de mesure, nommée comme en MusicXML.
enum Barline {
  /// Barre simple `|`.
  regular,

  /// Double barre `||`.
  lightLight,

  /// Barre finale `|]`.
  lightHeavy,
}

/// Mesure : des événements, puis éventuellement une barre.
class Measure {
  /// Crée une mesure.
  const new(this.events, {this.barline});

  /// Événements, de gauche à droite.
  final List<Event> events;

  /// Barre qui ferme la mesure, `null` si rien n'est écrit (fin du morceau
  /// sans barre, ou musique sans chiffrage).
  final Barline? barline;

  /// Durée totale, en rondes.
  Fraction get duration =>
      events.fold(Fraction.zero, (total, event) => total + event.duration);
}

/// Portée : clé, armure, chiffrage et mesures.
class Staff {
  /// Crée une portée. [id] la retrouve dans le système (voix ABC).
  const new({
    required this.clef,
    this.key = KeySignature.none,
    this.time,
    this.measures = const [],
    this.id,
  });

  /// Identifiant, `null` s'il n'est pas utile.
  final String? id;

  /// Clé.
  final Clef clef;

  /// Armure.
  final KeySignature key;

  /// Chiffrage, `null` pour une musique sans mesure.
  final TimeSignature? time;

  /// Mesures, de gauche à droite.
  final List<Measure> measures;

  /// Toutes les notes, de gauche à droite.
  Iterable<Note> get notes =>
      measures.expand((measure) => measure.events).whereType<Note>();

  /// Tous les événements avec leur mesure et leur index dans la mesure, de
  /// gauche à droite.
  Iterable<({int measure, int event, Event value})> get events sync* {
    for (final (measureIndex, measure) in measures.indexed) {
      for (final (eventIndex, event) in measure.events.indexed) {
        yield (measure: measureIndex, event: eventIndex, value: event);
      }
    }
  }
}

/// Signe qui regroupe les portées d'un groupe.
enum GroupSymbol {
  /// Aucun signe.
  none,

  /// Accolade (grande portée).
  brace,
}

/// Groupe de portées liées : barre initiale et barres de mesure communes,
/// éventuel signe.
class StaffGroup {
  /// Crée un groupe.
  const new(this.staves, {this.symbol = GroupSymbol.none});

  /// Grande portée : clé de sol et clé de fa liées par une accolade.
  new grand({List<Measure> upper = const [], List<Measure> lower = const []})
    : this([
        Staff(id: upperId, clef: Clef.treble, measures: upper),
        Staff(id: lowerId, clef: Clef.bass, measures: lower),
      ], symbol: GroupSymbol.brace);

  /// [Staff.id] de la portée du haut d'une grande portée.
  static const upperId = 'upper';

  /// [Staff.id] de la portée du bas d'une grande portée.
  static const lowerId = 'lower';

  /// Portées, de haut en bas.
  final List<Staff> staves;

  /// Signe de regroupement.
  final GroupSymbol symbol;
}

/// Désigne un événement du système. Index en base 0.
@immutable
class EventRef {
  /// Crée une référence.
  const new({required this.staff, required this.measure, required this.event});

  /// Index de la portée dans [System.staves].
  final int staff;

  /// Index de la mesure dans la portée.
  final int measure;

  /// Index de l'événement dans la mesure.
  final int event;

  @override
  bool operator ==(Object other) =>
      other is EventRef &&
      other.staff == staff &&
      other.measure == measure &&
      other.event == event;

  @override
  int get hashCode => Object.hash(staff, measure, event);

  @override
  String toString() => 'EventRef($staff, $measure, $event)';
}

/// Système : les groupes de portées lus ensemble.
class System {
  /// Crée un système.
  const new(this.groups);

  /// Système d'une seule portée.
  new single(Staff staff)
    : this([
        StaffGroup([staff]),
      ]);

  /// Groupes, de haut en bas.
  final List<StaffGroup> groups;

  /// Toutes les portées, de haut en bas.
  Iterable<Staff> get staves => groups.expand((group) => group.staves);

  /// Événement désigné par [ref], `null` s'il n'existe pas.
  Event? event(EventRef ref) {
    final staves = this.staves.toList();
    if (ref.staff < 0 || ref.staff >= staves.length) return null;
    final measures = staves[ref.staff].measures;
    if (ref.measure < 0 || ref.measure >= measures.length) return null;
    final events = measures[ref.measure].events;
    if (ref.event < 0 || ref.event >= events.length) return null;
    return events[ref.event];
  }

  /// Notes liées par des liaisons de prolongation à la note désignée par
  /// [ref], elle comprise, de gauche à droite. Un seul élément pour une note
  /// sans liaison ou un silence, vide si [ref] n'existe pas.
  List<EventRef> tieChain(EventRef ref) {
    switch (event(ref)) {
      case null:
        return const [];
      case Rest():
        return [ref];
      case Note():
    }
    final staff = staves.elementAt(ref.staff);
    final refs = [
      for (final (:measure, :event, value: _) in staff.events)
        EventRef(staff: ref.staff, measure: measure, event: event),
    ];
    final events = staff.events.map((entry) => entry.value).toList();
    bool tied(int index) => switch (events[index]) {
      Note(:final tiedToNext) => tiedToNext,
      Rest() => false,
    };

    var first = refs.indexOf(ref);
    while (first > 0 && tied(first - 1)) {
      first--;
    }
    var last = first;
    while (last < events.length - 1 && tied(last)) {
      last++;
    }
    return refs.sublist(first, last + 1);
  }
}
