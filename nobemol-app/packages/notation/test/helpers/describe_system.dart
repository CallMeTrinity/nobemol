import 'package:notation/notation.dart';

/// Résumé textuel d'un système, comparable à la ligne `% attendu :` des
/// exemples ABC.
///
/// `{RH:treble 1# 3/4(C5:2 E5:4 |]) LH:bass(C3)}` : groupes séparés par une
/// espace, accolade entre `{ }`, portée `id:clé armure chiffrage(mesures)`.
/// Une note est suivie de sa figure (`:2` blanche, `:4` noire), sauf la
/// ronde. Chaque mesure est suivie de sa barre, s'il y en a une.
String describeSystem(System system) => system.groups
    .map((group) {
      final staves = group.staves.map(_describeStaff).join(' ');
      return group.symbol == GroupSymbol.brace ? '{$staves}' : staves;
    })
    .join(' ');

String _describeStaff(Staff staff) {
  final id = staff.id == null ? '' : '${staff.id}:';
  final key = staff.key == KeySignature.none ? '' : ' ${staff.key}';
  final time = staff.time == null ? '' : ' ${staff.time}';
  final measures = staff.measures.map(_describeMeasure).join(' ');
  return '$id${_clefName(staff.clef)}$key$time($measures)';
}

String _describeMeasure(Measure measure) {
  final events = measure.events.map(
    (event) => switch (event) {
      Note(:final pitch, value: NoteValue.whole) => '$pitch',
      Note(:final pitch, :final value) =>
        '$pitch:${1 ~/ value.duration.toDouble()}',
    },
  );
  final barline = switch (measure.barline) {
    null => '',
    Barline.regular => ' |',
    Barline.lightLight => ' ||',
    Barline.lightHeavy => ' |]',
  };
  return '${events.join(' ')}$barline';
}

String _clefName(Clef clef) => switch (clef) {
  Clef.treble => 'treble',
  Clef.bass => 'bass',
  Clef.alto => 'alto',
  Clef.tenor => 'tenor',
  _ => '${clef.sign.name}${clef.line}',
};
