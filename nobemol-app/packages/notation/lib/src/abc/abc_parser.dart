import 'package:notation/src/abc/abc_exception.dart';
import 'package:notation/src/model/clef.dart';
import 'package:notation/src/model/pitch.dart';
import 'package:notation/src/model/system.dart';

/// Lit un morceau écrit dans le sous-ensemble ABC du moteur (`doc/abc.md`).
///
/// Tout ce qui sort du sous-ensemble lève une [AbcException], rien n'est
/// ignoré en silence.
System parseAbc(String source) => _Parser(source).parse();

/// Partie du morceau en cours de lecture.
enum _Phase { beforeX, header, body }

/// Voix ABC, future portée du modèle.
class _Voice {
  new(this.id, {required this.line, required this.column});

  /// Identifiant, `null` pour la voix unique d'un morceau sans `V:`.
  final String? id;

  /// Position de la première mention, pour les erreurs.
  final int line;
  final int column;

  Clef? clef;
  final notes = <Note>[];
}

/// Élément de `%%score` : une voix seule ou des voix sous accolade.
typedef _ScoreItem = ({List<String> ids, bool brace});

final _field = RegExp('^([A-Za-z]):');
final _voiceId = RegExp(r'^[A-Za-z0-9_]+$');
final _voiceIdPrefix = RegExp('[A-Za-z0-9_]+');
final _token = RegExp(r'\S+');

const Map<String, Clef> _clefs = {
  'treble': Clef.treble,
  'bass': Clef.bass,
  'alto': Clef.alto,
  'tenor': Clef.tenor,
};

const Map<String, DiatonicStep> _steps = {
  'C': DiatonicStep.c,
  'D': DiatonicStep.d,
  'E': DiatonicStep.e,
  'F': DiatonicStep.f,
  'G': DiatonicStep.g,
  'A': DiatonicStep.a,
  'B': DiatonicStep.b,
};

class _Parser {
  new(String source) : _lines = source.split('\n');

  final List<String> _lines;

  /// Ligne en cours, base 1.
  var _line = 0;

  /// Clé de `K:`, pour les voix qui n'en donnent pas.
  Clef? _keyClef;

  /// Voix dans l'ordre d'apparition.
  final _voices = <String?, _Voice>{};
  List<_ScoreItem>? _score;
  _Voice? _current;

  /// Vrai une fois `K:` lu.
  var _isBody = false;

  System parse() {
    var phase = _Phase.beforeX;
    int? blankLine;

    for (final (index, raw) in _lines.indexed) {
      _line = index + 1;
      final text = raw.endsWith('\r') ? raw.substring(0, raw.length - 1) : raw;
      if (text.trim().isEmpty) {
        if (phase != _Phase.beforeX) blankLine ??= _line;
        continue;
      }
      final isDirective = text.startsWith('%%');
      final content = isDirective
          ? '%%${_stripComment(text.substring(2))}'
          : _stripComment(text);
      if (content.trim().isEmpty) continue;

      if (blankLine != null) {
        throw AbcException(
          'ligne vide dans le morceau : en ABC, elle termine le morceau',
          line: blankLine,
          column: 1,
        );
      }
      if (isDirective) {
        _directive(content, phase);
        continue;
      }
      phase = switch (phase) {
        _Phase.beforeX => _start(content),
        _Phase.header => _header(content),
        _Phase.body => _body(content),
      };
    }

    switch (phase) {
      case _Phase.beforeX:
        throw const AbcException(
          'morceau vide : X: attendu',
          line: 1,
          column: 1,
        );
      case _Phase.header:
        throw AbcException(
          "K: attendu à la fin de l'en-tête",
          line: _lines.length,
          column: 1,
        );
      case _Phase.body:
        return _system();
    }
  }

  _Phase _start(String content) {
    final field = _field.firstMatch(content)?.group(1);
    if (field != 'X') {
      throw _error('le morceau doit commencer par X:', 1);
    }
    if (int.tryParse(content.substring(2).trim()) == null) {
      throw _error('numéro de morceau attendu après X:', 3);
    }
    return _Phase.header;
  }

  _Phase _header(String content) {
    final field = _field.firstMatch(content)?.group(1);
    final value = content.substring(2);
    switch (field) {
      case null:
        throw _error("K: attendu à la fin de l'en-tête, avant la musique", 1);
      case 'K':
        _key(value);
        return _Phase.body;
      case 'V':
        _voiceField(value);
        return _Phase.header;
      case 'T':
        throw _error(
          'champ T: non supporté : le titre va dans le fichier de la leçon',
          1,
        );
      default:
        throw _error(_unsupportedField(field), 1);
    }
  }

  _Phase _body(String content) {
    final field = _field.firstMatch(content)?.group(1);
    switch (field) {
      case null:
        _music(content);
      case 'V':
        _current = _voiceField(content.substring(2));
      case 'K':
        throw _error('changement de tonalité ou de clé non supporté', 1);
      default:
        throw _error(_unsupportedField(field), 1);
    }
    return _Phase.body;
  }

  String _unsupportedField(String field) => switch (field) {
    'M' => 'champ M: (mesure) non supporté (étape 3)',
    'L' => 'champ L: (unité de temps) non supporté (étape 3)',
    'X' => 'un seul X: par morceau',
    _ => 'champ $field: non supporté',
  };

  void _directive(String content, _Phase phase) {
    final name = _token.firstMatch(content)!.group(0)!;
    if (phase == _Phase.beforeX) {
      throw _error('le morceau doit commencer par X:', 1);
    }
    if (name != '%%score') {
      throw _error('directive $name non supportée', 1);
    }
    if (phase == _Phase.body) {
      throw _error("%%score se place dans l'en-tête, avant K:", 1);
    }
    if (_score != null) throw _error('%%score en double', 1);
    _score = _parseScore(content, name.length);
  }

  List<_ScoreItem> _parseScore(String content, int start) {
    final items = <_ScoreItem>[];
    final seen = <String>{};
    List<String>? brace;
    var braceColumn = 0;
    var index = start;

    while (index < content.length) {
      final char = content[index];
      final column = index + 1;
      if (char == ' ' || char == '\t') {
        index++;
      } else if (char == '{') {
        if (brace != null) throw _error('accolades imbriquées', column);
        brace = [];
        braceColumn = column;
        index++;
      } else if (char == '}') {
        if (brace == null) throw _error('« } » sans « { »', column);
        if (brace.length < 2) {
          throw _error('une accolade regroupe au moins deux voix', braceColumn);
        }
        items.add((ids: brace, brace: true));
        brace = null;
        index++;
      } else {
        final id = _voiceIdPrefix.matchAsPrefix(content, index)?.group(0);
        if (id == null) {
          throw _error(
            '« $char » non supporté dans %%score : '
            "seule l'accolade { } est prise en charge",
            column,
          );
        }
        if (!seen.add(id)) {
          throw _error('voix « $id » en double dans %%score', column);
        }
        if (brace != null) {
          brace.add(id);
        } else {
          items.add((ids: [id], brace: false));
        }
        index += id.length;
      }
    }

    if (brace != null) throw _error('« { » sans « } »', braceColumn);
    if (items.isEmpty) throw _error('%%score vide', 1);
    return items;
  }

  void _key(String value) {
    final tokens = _token.allMatches(value).toList();
    if (tokens.isEmpty) throw _error('tonalité attendue après K: (K:C)', 3);

    final key = tokens.first;
    final keyColumn = key.start + 3;
    if (key.group(0)!.startsWith('clef=')) {
      throw _error('tonalité attendue avant la clé (K:C clef=…)', keyColumn);
    }
    if (key.group(0) != 'C') {
      throw _error(
        'armure « ${key.group(0)} » non supportée (étape 3)',
        keyColumn,
      );
    }
    for (final token in tokens.skip(1)) {
      if (_keyClef != null) {
        throw _error('une seule clé par champ K:', token.start + 3);
      }
      _keyClef = _clef(token.group(0)!, token.start + 3, 'K:');
    }

    _isBody = true;

    // L'en-tête est complet : les voix déclarées doivent figurer dans
    // %%score.
    for (final voice in _voices.values) {
      _checkInScore(voice.id!, line: voice.line, column: voice.column);
    }
  }

  /// Lit un champ `V:` et renvoie la voix désignée.
  _Voice _voiceField(String value) {
    final tokens = _token.allMatches(value).toList();
    if (tokens.isEmpty) throw _error('identifiant de voix attendu', 3);

    final id = tokens.first.group(0)!;
    final idColumn = tokens.first.start + 3;
    if (!_voiceId.hasMatch(id)) {
      throw _error(
        'identifiant de voix « $id » invalide : lettres, chiffres ou _',
        idColumn,
      );
    }
    if (_voices.containsKey(null)) {
      throw _error(
        'musique avant le premier V: : '
        'avec des voix, toute la musique va dans une voix',
        1,
      );
    }

    var voice = _voices[id];
    if (voice == null) {
      if (_isBody) {
        _checkInScore(id, line: _line, column: idColumn);
      }
      voice = _voices[id] = _Voice(id, line: _line, column: idColumn);
    }

    for (final token in tokens.skip(1)) {
      final column = token.start + 3;
      final clef = _clef(token.group(0)!, column, 'V:');
      if (voice.clef != null && voice.clef != clef) {
        throw _error(
          'la voix « $id » a déjà une autre clé : '
          'une voix garde la même clé tout le morceau',
          column,
        );
      }
      voice.clef = clef;
    }
    return voice;
  }

  void _checkInScore(String id, {required int line, required int column}) {
    final score = _score;
    if (score == null || score.any((item) => item.ids.contains(id))) return;
    throw AbcException(
      'voix « $id » absente de %%score : elle ne serait pas affichée',
      line: line,
      column: column,
    );
  }

  Clef _clef(String token, int column, String field) {
    if (!token.startsWith('clef=')) {
      throw _error('propriété « $token » non supportée dans $field', column);
    }
    final name = token.substring('clef='.length);
    return _clefs[name] ??
        (throw _error(
          'clé inconnue « $name » (treble, bass, alto ou tenor)',
          column,
        ));
  }

  void _music(String content) {
    final voice = _current ??= _anonymousVoice(content);
    var index = 0;

    while (index < content.length) {
      final char = content[index];
      if (char == ' ' || char == '\t') {
        index++;
        continue;
      }

      final (accidental, length) = _accidental(content, index);
      index += length;
      if (index >= content.length || !_isNote(content[index])) {
        if (accidental != null) {
          throw _error("note attendue après l'altération", index + 1);
        }
        throw _error(_unexpected(content, index), index + 1);
      }

      final letter = content[index];
      final upper = letter.toUpperCase();
      final lowercase = letter != upper;
      var octave = lowercase ? 5 : 4;
      index++;

      while (index < content.length &&
          (content[index] == ',' || content[index] == "'")) {
        final mark = content[index];
        if (lowercase && mark == ',') {
          throw _error("« $letter, » s'écrit « $upper »", index + 1);
        }
        if (!lowercase && mark == "'") {
          throw _error(
            "« $letter' » s'écrit « ${letter.toLowerCase()} »",
            index + 1,
          );
        }
        octave += mark == ',' ? -1 : 1;
        index++;
      }

      voice.notes.add(
        Note(Pitch(_steps[upper]!, octave, accidental: accidental)),
      );
    }
  }

  /// Voix unique d'un morceau sans `V:`.
  _Voice _anonymousVoice(String content) {
    if (_voices.isNotEmpty || _score != null) {
      throw _error(
        'musique hors voix : ajouter une ligne V: avant',
        content.indexOf(_token) + 1,
      );
    }
    return _voices[null] = _Voice(null, line: _line, column: 1);
  }

  System _system() {
    // Une voix de %%score sans V: ni musique donne une portée vide.
    Staff staff(String? id) {
      final voice = _voices[id];
      return Staff(
        id: id,
        clef: voice?.clef ?? _keyClef ?? Clef.treble,
        notes: List.unmodifiable(voice?.notes ?? const <Note>[]),
      );
    }

    if (_score case final score?) {
      return System([
        for (final item in score)
          StaffGroup([
            for (final id in item.ids) staff(id),
          ], symbol: item.brace ? GroupSymbol.brace : GroupSymbol.none),
      ]);
    }
    if (_voices.isEmpty) return System.single(staff(null));
    return System([
      for (final id in _voices.keys) StaffGroup([staff(id)]),
    ]);
  }

  AbcException _error(String message, int column) =>
      AbcException(message, line: _line, column: column);
}

/// Texte avant le commentaire `%`.
String _stripComment(String text) {
  final index = text.indexOf('%');
  return index < 0 ? text : text.substring(0, index);
}

bool _isNote(String char) => _steps.containsKey(char.toUpperCase());

/// Altération écrite à [index] et nombre de caractères lus.
(Accidental?, int) _accidental(String content, int index) {
  if (content.startsWith('^^', index)) return (Accidental.doubleSharp, 2);
  if (content.startsWith('__', index)) return (Accidental.doubleFlat, 2);
  return switch (content[index]) {
    '^' => (Accidental.sharp, 1),
    '_' => (Accidental.flat, 1),
    '=' => (Accidental.natural, 1),
    _ => (null, 0),
  };
}

/// Message pour un caractère hors du sous-ensemble, avec l'étape qui
/// l'ajoutera.
String _unexpected(String content, int index) {
  final char = content[index];
  final next = index + 1 < content.length ? content[index + 1] : '';
  return switch (char) {
    '|' || ':' => 'barre de mesure non supportée (étape 3)',
    '[' when next == '|' => 'barre de mesure non supportée (étape 3)',
    '[' when _field.hasMatch(content.substring(index + 1)) =>
      'champ dans la ligne non supporté',
    '[' => 'accord non supporté (plus tard)',
    '/' => 'durée non supportée (étape 3)',
    'z' || 'Z' || 'x' || 'X' => 'silence non supporté (étape 4)',
    '-' => 'liaison de prolongation non supportée (étape 4)',
    '>' || '<' => 'rythme pointé non supporté (étape 4)',
    '!' || '+' || '.' || '~' => 'décoration non supportée (étape 5)',
    '(' || ')' => "liaison d'expression ou n-olet non supporté (plus tard)",
    '{' || '}' => "note d'ornement non supportée",
    '"' => 'annotation ou accord chiffré non supporté',
    r'\' => 'continuation de ligne non supportée',
    _ when int.tryParse(char) != null => 'durée non supportée (étape 3)',
    _ => 'caractère inattendu « $char »',
  };
}
