import 'package:notation/notation.dart';

/// Résumé textuel d'un système, comparable à la ligne `% attendu :` des
/// exemples ABC.
///
/// `{RH:treble 1# 3/4(C5:2 E5:4 |]) LH:bass(C3)}` : groupes séparés par une
/// espace, accolade entre `{ }`, portée `id:clé armure chiffrage(mesures)`.
/// Une note est suivie de sa figure (`:2` blanche, `:4` noire, `:8`
/// croche), sauf la ronde, puis de `.` si elle est pointée et de `-` si elle
/// est liée à la suivante. Un silence s'écrit `z`, avec sa figure. Les notes
/// ligaturées sont entre crochets. Les décorations précèdent leur note,
/// écrites comme en ABC (`!p!`, `.`, `"_dolce"`). Chaque mesure est suivie
/// de sa barre, s'il y en a une.
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
  final events = <String>[];
  var beamOpen = false;
  for (final event in measure.events) {
    final value = event.value == NoteValue.whole
        ? ''
        : ':${1 ~/ event.value.duration.toDouble()}';
    final dot = event.dotted ? '.' : '';
    final decorations = event.decorations.map(_describeDecoration).join();
    var text = switch (event) {
      Note(:final pitch, :final tiedToNext) =>
        '$decorations$pitch$value$dot${tiedToNext ? '-' : ''}',
      Rest() => '${decorations}z$value$dot',
    };
    final beamed = event is Note && event.beamedToNext;
    if (beamed && !beamOpen) text = '[$text';
    if (!beamed && beamOpen) text = '$text]';
    beamOpen = beamed;
    events.add(text);
  }
  final barline = switch (measure.barline) {
    null => '',
    Barline.regular => ' |',
    Barline.lightLight => ' ||',
    Barline.lightHeavy => ' |]',
  };
  return '${events.join(' ')}$barline';
}

String _describeDecoration(Decoration decoration) => switch (decoration) {
  Dynamic(:final name) => '!$name!',
  Articulation.staccato => '.',
  Articulation(:final name) => '!$name!',
  HairpinStart(:final hairpin) => '!${hairpin.name}(!',
  HairpinEnd(:final hairpin) => '!${hairpin.name})!',
  Annotation(:final text, placement: Placement.above) => '"^$text"',
  Annotation(:final text, placement: Placement.below) => '"_$text"',
};

String _clefName(Clef clef) => switch (clef) {
  Clef.treble => 'treble',
  Clef.bass => 'bass',
  Clef.alto => 'alto',
  Clef.tenor => 'tenor',
  _ => '${clef.sign.name}${clef.line}',
};
