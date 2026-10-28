// Télécharge Bravura et génère les métadonnées Dart des glyphes utilisés.
//
// Depuis packages/notation : dart run tool/bravura.dart
//
// Pour utiliser un nouveau glyphe : l'ajouter à `_glyphs`, relancer le script
// et committer la police et le fichier généré.
import 'dart:convert';
import 'dart:io';

/// Version de Bravura figée (tag du dépôt steinbergmedia/bravura).
const _bravuraVersion = '1.482';

/// Version de SMuFL figée (tag du dépôt w3c/smufl), pour les codepoints.
const _smuflVersion = 'v1.4';

const _bravuraBase =
    'https://raw.githubusercontent.com/steinbergmedia/bravura/'
    'bravura-$_bravuraVersion/redist';
const _glyphNamesUrl =
    'https://raw.githubusercontent.com/w3c/smufl/'
    '$_smuflVersion/metadata/glyphnames.json';

const _output = 'lib/src/layout/glyph.g.dart';

/// Glyphes utilisés par le moteur, par nom SMuFL.
final List<String> _glyphs = [
  'brace',
  'gClef',
  'cClef',
  'fClef',
  'noteheadWhole',
  'noteheadHalf',
  'noteheadBlack',
  'accidentalDoubleFlat',
  'accidentalFlat',
  'accidentalNatural',
  'accidentalSharp',
  'accidentalDoubleSharp',
  'augmentationDot',
  'flag8thUp',
  'flag8thDown',
  'flag16thUp',
  'flag16thDown',
  'restWhole',
  'restHalf',
  'restQuarter',
  'rest8th',
  'rest16th',
  'articStaccatoAbove',
  'articStaccatoBelow',
  'articTenutoAbove',
  'articTenutoBelow',
  'articAccentAbove',
  'articAccentBelow',
  'fermataAbove',
  'fermataBelow',
  'dynamicPPP',
  'dynamicPP',
  'dynamicPiano',
  'dynamicMP',
  'dynamicMF',
  'dynamicForte',
  'dynamicFF',
  'dynamicFFF',
  for (var digit = 0; digit <= 9; digit++) 'timeSig$digit',
];

/// Points d'ancrage utilisés par le moteur, s'ils existent pour le glyphe.
const _anchors = [
  'stemUpSE',
  'stemDownNW',
  'stemUpNW',
  'stemDownSW',
  'opticalCenter',
];

/// Valeurs de gravure par défaut utilisées par le moteur.
const _engravingDefaults = [
  'staffLineThickness',
  'legerLineThickness',
  'legerLineExtension',
  'thinBarlineThickness',
  'thickBarlineThickness',
  'barlineSeparation',
  'thinThickBarlineSeparation',
  'stemThickness',
  'beamThickness',
  'beamSpacing',
  'tieEndpointThickness',
  'tieMidpointThickness',
  'hairpinThickness',
];

Future<void> main() async {
  final client = HttpClient();
  try {
    await File('fonts/Bravura.otf')
        .writeAsBytes(await _get(client, '$_bravuraBase/otf/Bravura.otf'));
    await File('fonts/OFL.txt')
        .writeAsBytes(await _get(client, '$_bravuraBase/OFL.txt'));

    final metadata = _json(await _get(client, '$_bravuraBase/Bravura.json'));
    final names = _json(await _get(client, _glyphNamesUrl));

    await File(_output).writeAsString(_generate(metadata, names));
    await Process.run('dart', ['format', _output]);
  } finally {
    client.close();
  }
  stdout.writeln('Bravura $_bravuraVersion : police et métadonnées à jour.');
}

Future<List<int>> _get(HttpClient client, String url) async {
  final response = await (await client.getUrl(Uri.parse(url))).close();
  if (response.statusCode != HttpStatus.ok) {
    throw HttpException('${response.statusCode} sur $url');
  }
  final bytes = <int>[];
  await response.forEach(bytes.addAll);
  return bytes;
}

Map<String, dynamic> _json(List<int> bytes) =>
    jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

String _generate(Map<String, dynamic> metadata, Map<String, dynamic> names) {
  final bBoxes = metadata['glyphBBoxes'] as Map<String, dynamic>;
  final anchors = metadata['glyphsWithAnchors'] as Map<String, dynamic>;
  final defaults = metadata['engravingDefaults'] as Map<String, dynamic>;

  final out = StringBuffer()
    ..writeln('// GÉNÉRÉ par tool/bravura.dart, ne pas modifier à la main.')
    ..writeln('// Bravura $_bravuraVersion, SMuFL $_smuflVersion.')
    ..writeln()
    ..writeln('/// Glyphes SMuFL utilisés par le moteur.')
    ..writeln('///')
    ..writeln('/// Boîtes englobantes en interlignes, axe y vers le haut,')
    ..writeln('/// origine sur la ligne de base (convention SMuFL).')
    ..writeln("/// Ancres `null` si le glyphe n'en a pas.")
    ..writeln('enum Glyph {');

  for (final name in _glyphs) {
    final glyph = names[name] as Map<String, dynamic>;
    final codepoint = (glyph['codepoint'] as String).substring(2);
    final box = bBoxes[name] as Map<String, dynamic>;
    final sw = (box['bBoxSW'] as List).cast<num>();
    final ne = (box['bBoxNE'] as List).cast<num>();
    out
      ..writeln('  /// ${glyph['description']}.')
      ..writeln('  $name(')
      ..writeln('    codepoint: 0x$codepoint,')
      ..writeln('    bBoxSW: (${_double(sw[0])}, ${_double(sw[1])}),')
      ..writeln('    bBoxNE: (${_double(ne[0])}, ${_double(ne[1])}),');
    final glyphAnchors = anchors[name] as Map<String, dynamic>?;
    for (final anchor in _anchors) {
      final point = (glyphAnchors?[anchor] as List?)?.cast<num>();
      if (point != null) {
        out.writeln(
          '    $anchor: (${_double(point[0])}, ${_double(point[1])}),',
        );
      }
    }
    out.writeln('  ),');
  }

  out
    ..writeln('  ;')
    ..writeln()
    ..writeln('  new({')
    ..writeln('    required this.codepoint,')
    ..writeln('    required this.bBoxSW,')
    ..writeln('    required this.bBoxNE,')
    ..writeln('    this.stemUpSE,')
    ..writeln('    this.stemDownNW,')
    ..writeln('    this.stemUpNW,')
    ..writeln('    this.stemDownSW,')
    ..writeln('    this.opticalCenter,')
    ..writeln('  });')
    ..writeln()
    ..writeln('  /// Codepoint dans la police.')
    ..writeln('  final int codepoint;')
    ..writeln()
    ..writeln('  /// Coin bas gauche de la boîte englobante (x, y).')
    ..writeln('  final (double, double) bBoxSW;')
    ..writeln()
    ..writeln('  /// Coin haut droit de la boîte englobante (x, y).')
    ..writeln('  final (double, double) bBoxNE;')
    ..writeln()
    ..writeln("  /// Attache d'une hampe vers le haut (x, y).")
    ..writeln('  final (double, double)? stemUpSE;')
    ..writeln()
    ..writeln("  /// Attache d'une hampe vers le bas (x, y).")
    ..writeln('  final (double, double)? stemDownNW;')
    ..writeln()
    ..writeln("  /// Attache d'un crochet sur une hampe vers le haut (x, y).")
    ..writeln('  final (double, double)? stemUpNW;')
    ..writeln()
    ..writeln("  /// Attache d'un crochet sur une hampe vers le bas (x, y).")
    ..writeln('  final (double, double)? stemDownSW;')
    ..writeln()
    ..writeln('  /// Centre visuel, pour centrer une nuance sous sa note (x, y).')
    ..writeln('  final (double, double)? opticalCenter;')
    ..writeln('}')
    ..writeln()
    ..writeln('/// Valeurs de gravure par défaut de Bravura, en interlignes.')
    ..writeln('abstract final class EngravingDefaults {');

  for (final name in _engravingDefaults) {
    out
      ..writeln('  /// `$name`.')
      ..writeln('  static const $name = ${_double(defaults[name] as num)};');
  }

  out.writeln('}');
  return out.toString();
}

String _double(num value) {
  final text = value.toDouble().toString();
  return text == '-0.0' ? '0.0' : text;
}
