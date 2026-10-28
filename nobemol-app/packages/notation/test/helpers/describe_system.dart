import 'package:notation/notation.dart';

/// Résumé textuel d'un système, comparable à la ligne `% attendu :` des
/// exemples ABC.
///
/// `{RH:treble(C5 E5) LH:bass(C3)}` : groupes séparés par une espace,
/// accolade entre `{ }`, portée `id:clé(notes)`.
String describeSystem(System system) => system.groups
    .map((group) {
      final staves = group.staves.map(_describeStaff).join(' ');
      return group.symbol == GroupSymbol.brace ? '{$staves}' : staves;
    })
    .join(' ');

String _describeStaff(Staff staff) {
  final id = staff.id == null ? '' : '${staff.id}:';
  final notes = staff.notes.map((note) => note.pitch).join(' ');
  return '$id${_clefName(staff.clef)}($notes)';
}

String _clefName(Clef clef) => switch (clef) {
  Clef.treble => 'treble',
  Clef.bass => 'bass',
  Clef.alto => 'alto',
  Clef.tenor => 'tenor',
  _ => '${clef.sign.name}${clef.line}',
};
