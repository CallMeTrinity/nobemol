import 'package:meta/meta.dart';

/// Signe attaché à une note ou à un silence : nuance, articulation, début ou
/// fin de soufflet, texte.
sealed class Decoration;

/// Nuance, du plus doux au plus fort.
enum Dynamic implements Decoration {
  /// Pianississimo.
  ppp,

  /// Pianissimo.
  pp,

  /// Piano.
  p,

  /// Mezzo piano.
  mp,

  /// Mezzo forte.
  mf,

  /// Forte.
  f,

  /// Fortissimo.
  ff,

  /// Fortississimo.
  fff,
}

/// Articulation, point d'orgue compris : une par note au plus.
enum Articulation implements Decoration {
  /// Point : note détachée, raccourcie.
  staccato,

  /// Trait : note tenue sur toute sa durée.
  tenuto,

  /// Accent `>`.
  accent,

  /// Point d'orgue : seule articulation admise sur un silence.
  fermata,
}

/// Sens d'un soufflet.
enum Hairpin {
  /// De plus en plus fort : le soufflet s'ouvre.
  crescendo,

  /// De moins en moins fort : le soufflet se ferme.
  diminuendo,
}

/// Début d'un soufflet, sur sa première note.
@immutable
class HairpinStart implements Decoration {
  /// Crée un début de soufflet.
  const new(this.hairpin);

  /// Sens du soufflet.
  final Hairpin hairpin;

  @override
  bool operator ==(Object other) =>
      other is HairpinStart && other.hairpin == hairpin;

  @override
  int get hashCode => Object.hash(HairpinStart, hairpin);

  @override
  String toString() => 'HairpinStart(${hairpin.name})';
}

/// Fin d'un soufflet, sur sa dernière note. Le soufflet appartient à sa
/// première note : la fin n'est qu'un repère.
@immutable
class HairpinEnd implements Decoration {
  /// Crée une fin de soufflet.
  const new(this.hairpin);

  /// Sens du soufflet.
  final Hairpin hairpin;

  @override
  bool operator ==(Object other) =>
      other is HairpinEnd && other.hairpin == hairpin;

  @override
  int get hashCode => Object.hash(HairpinEnd, hairpin);

  @override
  String toString() => 'HairpinEnd(${hairpin.name})';
}

/// Place d'un texte par rapport à la portée.
enum Placement {
  /// Au-dessus de la portée.
  above,

  /// Au-dessous de la portée.
  below,
}

/// Texte en italique au-dessus ou au-dessous de la portée, aligné sur le
/// début de la note : un terme (« dolce », « cresc. », « a tempo »).
@immutable
class Annotation implements Decoration {
  /// Crée une annotation.
  const new(this.text, {required this.placement});

  /// Texte affiché.
  final String text;

  /// Au-dessus ou au-dessous de la portée.
  final Placement placement;

  @override
  bool operator ==(Object other) =>
      other is Annotation && other.text == text && other.placement == placement;

  @override
  int get hashCode => Object.hash(text, placement);

  @override
  String toString() => 'Annotation($text, ${placement.name})';
}
