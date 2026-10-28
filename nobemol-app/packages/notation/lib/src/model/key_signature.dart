import 'package:meta/meta.dart';
import 'package:notation/src/model/pitch.dart';

/// Armure : un nombre de dièses (positif) ou de bémols (négatif).
///
/// Pas de tonique ni de mode : sol majeur et mi mineur s'écrivent pareil, et
/// la lecture ne dépend que de l'armure.
@immutable
class KeySignature {
  /// Crée une armure. [fifths] va de -7 (7 bémols) à 7 (7 dièses).
  const new(this.fifths)
    : assert(fifths >= -7 && fifths <= 7, 'de 7 bémols à 7 dièses');

  /// Pas d'altération (do majeur, la mineur).
  static const none = KeySignature(0);

  /// Ordre des dièses. Les bémols suivent l'ordre inverse.
  static const List<DiatonicStep> _sharpOrder = [
    DiatonicStep.f,
    DiatonicStep.c,
    DiatonicStep.g,
    DiatonicStep.d,
    DiatonicStep.a,
    DiatonicStep.e,
    DiatonicStep.b,
  ];

  /// Nombre de dièses si positif, de bémols si négatif.
  final int fifths;

  /// Altération de l'armure, `null` sans altération.
  Accidental? get accidental => switch (fifths) {
    0 => null,
    > 0 => Accidental.sharp,
    _ => Accidental.flat,
  };

  /// Degrés altérés, dans l'ordre où l'armure les écrit.
  List<DiatonicStep> get steps => fifths >= 0
      ? _sharpOrder.take(fifths).toList()
      : _sharpOrder.reversed.take(-fifths).toList();

  @override
  bool operator ==(Object other) =>
      other is KeySignature && other.fifths == fifths;

  @override
  int get hashCode => fifths.hashCode;

  @override
  String toString() => switch (fifths) {
    0 => '0',
    > 0 => '$fifths#',
    _ => '${-fifths}b',
  };
}
