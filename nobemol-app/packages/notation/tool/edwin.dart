// Télécharge Edwin Italic, la police des textes (termes), et génère ses
// métriques en Dart : le layout mesure les textes sans Flutter.
//
// Depuis packages/notation : dart run tool/edwin.dart
//
// Edwin (MuseScore, licence SIL OFL) est la police de texte que Bravura
// recommande après Academico, introuvable en ligne (`textFontFamily` dans
// les métadonnées de Bravura).
import 'dart:io';
import 'dart:typed_data';

/// Version de MuseScore figée (tag du dépôt musescore/MuseScore).
const _museScoreVersion = 'v4.7.6';

const _edwinBase =
    'https://raw.githubusercontent.com/musescore/MuseScore/'
    '$_museScoreVersion/fonts/edwin';

const _output = 'lib/src/layout/text_font.g.dart';

/// Caractères mesurés : ASCII imprimable et lettres accentuées du Latin-1.
/// Le parser n'accepte que des lettres, des chiffres, l'espace et `.,'-`.
final List<int> _codes = [
  for (var code = 0x20; code <= 0x7E; code++) code,
  for (var code = 0xC0; code <= 0xFF; code++)
    if (code != 0xD7 && code != 0xF7) code,
];

Future<void> main() async {
  final client = HttpClient();
  try {
    final font = await _get(client, '$_edwinBase/Edwin-Italic.otf');
    await File('fonts/Edwin-Italic.otf').writeAsBytes(font);
    await File(
      'fonts/Edwin-OFL.txt',
    ).writeAsBytes(await _get(client, '$_edwinBase/LICENSE.txt'));

    await File(_output).writeAsString(_generate(_Font(font)));
    await Process.run('dart', ['format', _output]);
  } finally {
    client.close();
  }
  stdout.writeln('Edwin ($_museScoreVersion) : police et métriques à jour.');
}

Future<Uint8List> _get(HttpClient client, String url) async {
  final response = await (await client.getUrl(Uri.parse(url))).close();
  if (response.statusCode != HttpStatus.ok) {
    throw HttpException('${response.statusCode} sur $url');
  }
  final bytes = BytesBuilder(copy: false);
  await response.forEach(bytes.add);
  return bytes.takeBytes();
}

/// Lecture des quelques tables OpenType utiles : `head`, `hhea`, `OS/2`,
/// `cmap` (format 4) et `hmtx`.
class _Font {
  new(Uint8List bytes) : _data = ByteData.sublistView(bytes) {
    final count = _data.getUint16(4);
    for (var index = 0; index < count; index++) {
      final record = 12 + 16 * index;
      final tag = String.fromCharCodes(bytes.sublist(record, record + 4));
      _tables[tag] = _data.getUint32(record + 8);
    }
  }

  final ByteData _data;
  final _tables = <String, int>{};

  int _table(String tag) =>
      _tables[tag] ?? (throw FormatException('table $tag absente'));

  late final int unitsPerEm = _data.getUint16(_table('head') + 18);

  late final int ascender = _data.getInt16(_table('hhea') + 4);

  late final int descender = _data.getInt16(_table('hhea') + 6);

  late final int xHeight = _data.getInt16(_table('OS/2') + 86);

  /// Chasse du glyphe [glyph] : les derniers glyphes partagent la dernière
  /// chasse de la table.
  int advance(int glyph) {
    final count = _data.getUint16(_table('hhea') + 34);
    final index = glyph < count ? glyph : count - 1;
    return _data.getUint16(_table('hmtx') + 4 * index);
  }

  /// Glyphe du caractère [code], 0 s'il n'existe pas. Sous-table Windows
  /// Unicode BMP (3, 1), format 4.
  int glyph(int code) {
    final cmap = _table('cmap');
    int? subtable;
    for (var index = 0; index < _data.getUint16(cmap + 2); index++) {
      final record = cmap + 4 + 8 * index;
      if (_data.getUint16(record) == 3 && _data.getUint16(record + 2) == 1) {
        subtable = cmap + _data.getUint32(record + 4);
      }
    }
    if (subtable == null || _data.getUint16(subtable) != 4) {
      throw const FormatException('sous-table cmap (3, 1) format 4 absente');
    }

    final segments = _data.getUint16(subtable + 6) ~/ 2;
    final ends = subtable + 14;
    final starts = ends + 2 * segments + 2;
    final deltas = starts + 2 * segments;
    final rangeOffsets = deltas + 2 * segments;
    for (var segment = 0; segment < segments; segment++) {
      if (code > _data.getUint16(ends + 2 * segment)) continue;
      final start = _data.getUint16(starts + 2 * segment);
      if (code < start) return 0;
      final delta = _data.getInt16(deltas + 2 * segment);
      final offsetAddress = rangeOffsets + 2 * segment;
      final rangeOffset = _data.getUint16(offsetAddress);
      if (rangeOffset == 0) return (code + delta) & 0xFFFF;
      final glyph = _data.getUint16(
        offsetAddress + rangeOffset + 2 * (code - start),
      );
      return glyph == 0 ? 0 : (glyph + delta) & 0xFFFF;
    }
    return 0;
  }
}

String _generate(_Font font) {
  String em(int units) => _double(units / font.unitsPerEm);

  final out = StringBuffer()
    ..writeln('// GÉNÉRÉ par tool/edwin.dart, ne pas modifier à la main.')
    ..writeln('// Edwin Italic, MuseScore $_museScoreVersion.')
    ..writeln()
    ..writeln('/// Métriques de la police des textes (Edwin Italic), en em.')
    ..writeln('abstract final class TextFont {')
    ..writeln('  /// Hauteur des ascendantes au-dessus de la ligne de base.')
    ..writeln('  static const ascender = ${em(font.ascender)};')
    ..writeln()
    ..writeln('  /// Profondeur des descendantes sous la ligne de base.')
    ..writeln('  static const descender = ${em(-font.descender)};')
    ..writeln()
    ..writeln("  /// Hauteur d'x.")
    ..writeln('  static const xHeight = ${em(font.xHeight)};')
    ..writeln()
    ..writeln('  /// Chasse de chaque caractère, par code.')
    ..writeln('  static const Map<int, double> advances = {');
  for (final code in _codes) {
    final glyph = font.glyph(code);
    if (glyph == 0) continue;
    final hex = code.toRadixString(16).toUpperCase().padLeft(4, '0');
    out.writeln('    0x$hex: ${em(font.advance(glyph))},');
  }
  out
    ..writeln('  };')
    ..writeln('}');
  return out.toString();
}

String _double(num value) {
  final text = value.toDouble().toString();
  return text == '-0.0' ? '0.0' : text;
}
