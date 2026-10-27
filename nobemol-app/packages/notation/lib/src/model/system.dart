import 'package:notation/src/model/clef.dart';
import 'package:notation/src/model/pitch.dart';

/// Note sans durée (pas encore de rythme : une tête de ronde).
class Note {
  /// Crée une note.
  const new(this.pitch);

  /// Hauteur.
  final Pitch pitch;
}

/// Portée : une clé et ses notes.
class Staff {
  /// Crée une portée. [id] la retrouve dans le système (voix ABC à venir).
  const new({required this.clef, this.notes = const [], this.id});

  /// Identifiant, `null` s'il n'est pas utile.
  final String? id;

  /// Clé.
  final Clef clef;

  /// Notes, de gauche à droite.
  final List<Note> notes;
}

/// Signe qui regroupe les portées d'un groupe.
enum GroupSymbol {
  /// Aucun signe.
  none,

  /// Accolade (grande portée).
  brace,
}

/// Groupe de portées liées : barre initiale commune et éventuel signe.
class StaffGroup {
  /// Crée un groupe.
  const new(this.staves, {this.symbol = GroupSymbol.none});

  /// Grande portée : clé de sol et clé de fa liées par une accolade.
  new grand({List<Note> upper = const [], List<Note> lower = const []})
    : this([
        Staff(id: upperId, clef: Clef.treble, notes: upper),
        Staff(id: lowerId, clef: Clef.bass, notes: lower),
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
}
