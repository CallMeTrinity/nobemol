import 'package:notation/src/abc/abc_exception.dart';
import 'package:notation/src/model/clef.dart';
import 'package:notation/src/model/fraction.dart';
import 'package:notation/src/model/key_signature.dart';
import 'package:notation/src/model/pitch.dart';
import 'package:notation/src/model/system.dart';
import 'package:notation/src/model/time_signature.dart';

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

  /// Mesures fermées par une barre.
  final measures = <Measure>[];

  /// Événements de la mesure en cours.
  final events = <Event>[];

  /// Position de la dernière note, pour une mesure finale sans barre.
  int lastLine = 0;
  int lastColumn = 0;
}

/// Élément de `%%score` : une voix seule ou des voix sous accolade.
typedef _ScoreItem = ({List<String> ids, bool brace});

final _field = RegExp('^([A-Za-z]):');
final _voiceId = RegExp(r'^[A-Za-z0-9_]+$');
final _voiceIdPrefix = RegExp('[A-Za-z0-9_]+');
final _token = RegExp(r'\S+');
final _digits = RegExp('[0-9]+');
final _meter = RegExp(r'^([0-9]+)/([0-9]+)$');
final _unitLength = RegExp(r'^1/([0-9]+)$');
final _keyName = RegExp(r'^([A-G])([#b]?)(m?)$');

/// Dénominateurs acceptés dans M: et L:.
const _denominators = {1, 2, 4, 8, 16};

/// Dièses (positif) ou bémols (négatif) de la tonalité majeure de chaque
/// lettre.
const Map<String, int> _majorFifths = {
  'F': -1,
  'C': 0,
  'G': 1,
  'D': 2,
  'A': 3,
  'E': 4,
  'B': 5,
};

/// Figures acceptées, par durée en rondes.
final Map<Fraction, NoteValue> _noteValues = {
  for (final value in NoteValue.values) value.duration: value,
};

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

  /// Armure de `K:`.
  KeySignature _keySignature = KeySignature.none;

  /// Chiffrage de `M:`, `null` sans mesures.
  TimeSignature? _time;

  /// Unité de temps de `L:`, obligatoire dès qu'il y a une note.
  Fraction? _unit;

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
      case 'M':
        if (_time != null) throw _error('M: en double', 1);
        _time = _meterField(value);
        return _Phase.header;
      case 'L':
        if (_unit != null) throw _error('L: en double', 1);
        _unit = _unitField(value);
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
    'M' => "changement de chiffrage non supporté : M: va dans l'en-tête",
    'L' => "changement d'unité de temps non supporté : L: va dans l'en-tête",
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
    _keySignature = _keySignatureOf(key.group(0)!, keyColumn);
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

  TimeSignature _meterField(String value) {
    final text = value.trim();
    final column = value.indexOf(_token) + 3;
    final match = _meter.firstMatch(text);
    if (match == null) {
      throw _error(switch (text) {
        '' => 'chiffrage attendu après M: (M:4/4)',
        'C' => 'M:C non supporté : écrire M:4/4',
        'C|' => 'M:C| non supporté : écrire M:2/2',
        'none' => 'M:none non supporté : sans mesures, omettre M:',
        _ => 'chiffrage « $text » invalide (M:3/4)',
      }, column);
    }
    final beats = int.parse(match.group(1)!);
    final beatUnit = int.parse(match.group(2)!);
    if (beats < 1 || beats > 12) {
      throw _error('chiffre du haut de 1 à 12 attendu', column);
    }
    if (!_denominators.contains(beatUnit)) {
      throw _error('chiffre du bas : 1, 2, 4, 8 ou 16', column);
    }
    return TimeSignature(beats, beatUnit);
  }

  Fraction _unitField(String value) {
    final text = value.trim();
    final denominator = int.tryParse(
      _unitLength.firstMatch(text)?.group(1) ?? '',
    );
    if (denominator == null || !_denominators.contains(denominator)) {
      throw _error(
        'unité de temps « $text » invalide : 1/1, 1/2, 1/4, 1/8 ou 1/16',
        value.indexOf(_token) + 3,
      );
    }
    return Fraction(1, denominator);
  }

  /// Armure de la tonalité [name] : `G` (sol majeur), `Bbm` (si bémol
  /// mineur)...
  KeySignature _keySignatureOf(String name, int column) {
    final match = _keyName.firstMatch(name);
    if (match == null) {
      throw _error(
        'tonalité « $name » non supportée : '
        'majeure (G, Bb, F#) ou mineure (Em, Bbm)',
        column,
      );
    }
    final fifths =
        _majorFifths[match.group(1)]! +
        switch (match.group(2)) {
          '#' => 7,
          'b' => -7,
          _ => 0,
        } -
        (match.group(3) == 'm' ? 3 : 0);
    if (fifths.abs() > 7) {
      throw _error(
        'tonalité « $name » : plus de 7 altérations, '
        "écrire l'enharmonique",
        column,
      );
    }
    return KeySignature(fifths);
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
      if (char == '|') {
        index = _barline(voice, content, index);
        continue;
      }

      final noteColumn = index + 1;
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

      final (multiplier, end) = _duration(content, index);
      index = end;
      voice
        ..events.add(
          Note(
            Pitch(_steps[upper]!, octave, accidental: accidental),
            value: _noteValue(multiplier, noteColumn),
          ),
        )
        ..lastLine = _line
        ..lastColumn = noteColumn;
    }
  }

  /// Lit la barre qui commence à [index], ferme la mesure en cours et
  /// renvoie l'index qui suit la barre.
  int _barline(_Voice voice, String content, int index) {
    final column = index + 1;
    final next = index + 1 < content.length ? content[index + 1] : '';
    final (barline, length) = switch (next) {
      '|' => (Barline.lightLight, 2),
      ']' => (Barline.lightHeavy, 2),
      ':' => throw _error('reprise non supportée', column),
      _ when int.tryParse(next) != null => throw _error(
        'fin alternative non supportée',
        column,
      ),
      _ => (Barline.regular, 1),
    };

    final time = _time;
    if (time == null) {
      throw _error(
        "barre de mesure sans chiffrage : ajouter M: dans l'en-tête",
        column,
      );
    }
    if (voice.events.isEmpty) {
      throw _error(
        voice.measures.isEmpty
            ? 'barre de mesure avant la première note'
            : 'mesure vide (silences : étape 4)',
        column,
      );
    }
    _closeMeasure(voice, time, barline, line: _line, column: column);
    return index + length;
  }

  /// Ajoute la mesure en cours de [voice], après avoir vérifié sa durée.
  void _closeMeasure(
    _Voice voice,
    TimeSignature time,
    Barline? barline, {
    required int line,
    required int column,
  }) {
    final measure = Measure(List.unmodifiable(voice.events), barline: barline);
    final expected = time.measureDuration;
    if (measure.duration != expected) {
      final problem = measure.duration < expected
          ? 'incomplète'
          : 'trop longue';
      throw AbcException(
        'mesure ${voice.measures.length + 1} $problem : '
        '${_inBeats(measure.duration, time)} au lieu de $time',
        line: line,
        column: column,
      );
    }
    voice.measures.add(measure);
    voice.events.clear();
  }

  /// Multiplicateur de durée (`2`, `/2`, `3/2`, `/`, `//`) à [index], et
  /// index qui le suit.
  (Fraction, int) _duration(String content, int index) {
    var end = index;
    var numerator = 1;
    final digits = _digits.matchAsPrefix(content, end);
    if (digits != null) {
      numerator = int.parse(digits.group(0)!);
      if (numerator == 0) throw _error('durée nulle', index + 1);
      end = digits.end;
    }

    var slashes = 0;
    while (end < content.length && content[end] == '/') {
      slashes++;
      end++;
    }
    if (slashes == 0) return (Fraction(numerator), end);

    final denominator = _digits.matchAsPrefix(content, end);
    if (denominator == null) {
      return (Fraction(numerator, 1 << slashes), end);
    }
    final value = int.parse(denominator.group(0)!);
    if (slashes > 1 || value == 0) {
      throw _error(
        'durée « ${content.substring(index, denominator.end)} » invalide',
        index + 1,
      );
    }
    return (Fraction(numerator, value), denominator.end);
  }

  /// Figure d'une note de durée [multiplier] × `L:`.
  NoteValue _noteValue(Fraction multiplier, int column) {
    final unit = _unit;
    if (unit == null) {
      throw _error(
        "unité de temps manquante : ajouter L: dans l'en-tête (L:1/4)",
        column,
      );
    }
    final duration = unit * multiplier;
    if (_noteValues[duration] case final value?) return value;

    final numerator = duration.reduced.numerator;
    throw _error(switch (duration) {
      _ when numerator == 3 || numerator == 7 =>
        'note pointée non supportée (étape 4)',
      _ when duration < NoteValue.quarter.duration =>
        'croche et valeurs plus courtes non supportées (étape 4)',
      _ when duration > NoteValue.whole.duration =>
        "durée plus longue qu'une ronde non supportée",
      _ => 'durée de $duration de ronde non supportée',
    }, column);
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
    _closeVoices();

    // Une voix de %%score sans V: ni musique donne une portée vide.
    Staff staff(String? id) {
      final voice = _voices[id];
      return Staff(
        id: id,
        clef: voice?.clef ?? _keyClef ?? Clef.treble,
        key: _keySignature,
        time: _time,
        measures: List.unmodifiable(voice?.measures ?? const <Measure>[]),
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

  /// Ferme la dernière mesure de chaque voix, puis vérifie que les voix
  /// s'alignent : même nombre de mesures, mêmes barres.
  void _closeVoices() {
    final time = _time;
    for (final voice in _voices.values) {
      if (voice.events.isEmpty) continue;
      if (time == null) {
        voice.measures.add(Measure(List.unmodifiable(voice.events)));
        voice.events.clear();
      } else {
        _closeMeasure(
          voice,
          time,
          null,
          line: voice.lastLine,
          column: voice.lastColumn,
        );
      }
    }

    // Une voix sans musique donne une portée vide, sans mesure.
    final voices = _voices.values.where((voice) => voice.measures.isNotEmpty);
    final reference = voices.firstOrNull;
    if (reference == null) return;
    for (final voice in voices.skip(1)) {
      AbcException error(String message) =>
          AbcException(message, line: voice.line, column: voice.column);
      if (voice.measures.length != reference.measures.length) {
        throw error(
          'la voix « ${voice.id} » a ${voice.measures.length} mesure(s) et '
          '« ${reference.id} » en a ${reference.measures.length} : '
          'les voix doivent avoir le même nombre de mesures',
        );
      }
      for (final (index, measure) in voice.measures.indexed) {
        if (measure.barline != reference.measures[index].barline) {
          throw error(
            'mesure ${index + 1} : la voix « ${voice.id} » ne finit pas '
            'par la même barre que « ${reference.id} »',
          );
        }
      }
    }
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

/// Écrit [duration] dans l'unité du chiffrage quand c'est possible : `4/8`
/// en 6/8, plutôt que `1/2`.
String _inBeats(Fraction duration, TimeSignature time) {
  final beats = duration * Fraction(time.beatUnit);
  return beats.isInteger ? '$beats/${time.beatUnit}' : '$duration';
}

/// Message pour un caractère hors du sous-ensemble, avec l'étape qui
/// l'ajoutera.
String _unexpected(String content, int index) {
  final char = content[index];
  final next = index + 1 < content.length ? content[index + 1] : '';
  return switch (char) {
    ':' => 'reprise non supportée',
    '[' when next == '|' => 'barre « [| » non supportée',
    '[' when _field.hasMatch(content.substring(index + 1)) =>
      'champ dans la ligne non supporté',
    '[' => 'accord non supporté (plus tard)',
    ']' => 'caractère inattendu « ] »',
    '/' => 'durée sans note : pas d’espace entre une note et sa durée',
    'z' || 'Z' || 'x' || 'X' => 'silence non supporté (étape 4)',
    '-' => 'liaison de prolongation non supportée (étape 4)',
    '>' || '<' => 'rythme pointé non supporté (étape 4)',
    '!' || '+' || '.' || '~' => 'décoration non supportée (étape 5)',
    '(' || ')' => "liaison d'expression ou n-olet non supporté (plus tard)",
    '{' || '}' => "note d'ornement non supportée",
    '"' => 'annotation ou accord chiffré non supporté',
    r'\' => 'continuation de ligne non supportée',
    _ when int.tryParse(char) != null =>
      'durée sans note : pas d’espace entre une note et sa durée',
    _ => 'caractère inattendu « $char »',
  };
}
