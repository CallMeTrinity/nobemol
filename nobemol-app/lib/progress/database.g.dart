// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SessionsTable extends Sessions
    with TableInfo<$SessionsTable, SessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _lessonIdMeta = const VerificationMeta(
    'lessonId',
  );
  @override
  late final GeneratedColumn<String> lessonId = GeneratedColumn<String>(
    'lesson_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
    'finished_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionsMeta = const VerificationMeta(
    'questions',
  );
  @override
  late final GeneratedColumn<int> questions = GeneratedColumn<int>(
    'questions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _correctMeta = const VerificationMeta(
    'correct',
  );
  @override
  late final GeneratedColumn<int> correct = GeneratedColumn<int>(
    'correct',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _xpMeta = const VerificationMeta('xp');
  @override
  late final GeneratedColumn<int> xp = GeneratedColumn<int>(
    'xp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bestComboMeta = const VerificationMeta(
    'bestCombo',
  );
  @override
  late final GeneratedColumn<int> bestCombo = GeneratedColumn<int>(
    'best_combo',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    lessonId,
    startedAt,
    finishedAt,
    questions,
    correct,
    xp,
    bestCombo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('lesson_id')) {
      context.handle(
        _lessonIdMeta,
        lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_finishedAtMeta);
    }
    if (data.containsKey('questions')) {
      context.handle(
        _questionsMeta,
        questions.isAcceptableOrUnknown(data['questions']!, _questionsMeta),
      );
    } else if (isInserting) {
      context.missing(_questionsMeta);
    }
    if (data.containsKey('correct')) {
      context.handle(
        _correctMeta,
        correct.isAcceptableOrUnknown(data['correct']!, _correctMeta),
      );
    } else if (isInserting) {
      context.missing(_correctMeta);
    }
    if (data.containsKey('xp')) {
      context.handle(_xpMeta, xp.isAcceptableOrUnknown(data['xp']!, _xpMeta));
    } else if (isInserting) {
      context.missing(_xpMeta);
    }
    if (data.containsKey('best_combo')) {
      context.handle(
        _bestComboMeta,
        bestCombo.isAcceptableOrUnknown(data['best_combo']!, _bestComboMeta),
      );
    } else if (isInserting) {
      context.missing(_bestComboMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      lessonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lesson_id'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      )!,
      questions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}questions'],
      )!,
      correct: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct'],
      )!,
      xp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}xp'],
      )!,
      bestCombo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}best_combo'],
      )!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class SessionRow extends DataClass implements Insertable<SessionRow> {
  final int id;

  /// Leçon jouée, `null` en lecture libre (point de départ).
  final String? lessonId;
  final DateTime startedAt;
  final DateTime finishedAt;
  final int questions;
  final int correct;
  final int xp;
  final int bestCombo;
  const SessionRow({
    required this.id,
    this.lessonId,
    required this.startedAt,
    required this.finishedAt,
    required this.questions,
    required this.correct,
    required this.xp,
    required this.bestCombo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || lessonId != null) {
      map['lesson_id'] = Variable<String>(lessonId);
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    map['finished_at'] = Variable<DateTime>(finishedAt);
    map['questions'] = Variable<int>(questions);
    map['correct'] = Variable<int>(correct);
    map['xp'] = Variable<int>(xp);
    map['best_combo'] = Variable<int>(bestCombo);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      lessonId: lessonId == null && nullToAbsent
          ? const Value.absent()
          : Value(lessonId),
      startedAt: Value(startedAt),
      finishedAt: Value(finishedAt),
      questions: Value(questions),
      correct: Value(correct),
      xp: Value(xp),
      bestCombo: Value(bestCombo),
    );
  }

  factory SessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionRow(
      id: serializer.fromJson<int>(json['id']),
      lessonId: serializer.fromJson<String?>(json['lessonId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      finishedAt: serializer.fromJson<DateTime>(json['finishedAt']),
      questions: serializer.fromJson<int>(json['questions']),
      correct: serializer.fromJson<int>(json['correct']),
      xp: serializer.fromJson<int>(json['xp']),
      bestCombo: serializer.fromJson<int>(json['bestCombo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lessonId': serializer.toJson<String?>(lessonId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'finishedAt': serializer.toJson<DateTime>(finishedAt),
      'questions': serializer.toJson<int>(questions),
      'correct': serializer.toJson<int>(correct),
      'xp': serializer.toJson<int>(xp),
      'bestCombo': serializer.toJson<int>(bestCombo),
    };
  }

  SessionRow copyWith({
    int? id,
    Value<String?> lessonId = const Value.absent(),
    DateTime? startedAt,
    DateTime? finishedAt,
    int? questions,
    int? correct,
    int? xp,
    int? bestCombo,
  }) => SessionRow(
    id: id ?? this.id,
    lessonId: lessonId.present ? lessonId.value : this.lessonId,
    startedAt: startedAt ?? this.startedAt,
    finishedAt: finishedAt ?? this.finishedAt,
    questions: questions ?? this.questions,
    correct: correct ?? this.correct,
    xp: xp ?? this.xp,
    bestCombo: bestCombo ?? this.bestCombo,
  );
  SessionRow copyWithCompanion(SessionsCompanion data) {
    return SessionRow(
      id: data.id.present ? data.id.value : this.id,
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
      questions: data.questions.present ? data.questions.value : this.questions,
      correct: data.correct.present ? data.correct.value : this.correct,
      xp: data.xp.present ? data.xp.value : this.xp,
      bestCombo: data.bestCombo.present ? data.bestCombo.value : this.bestCombo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionRow(')
          ..write('id: $id, ')
          ..write('lessonId: $lessonId, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('questions: $questions, ')
          ..write('correct: $correct, ')
          ..write('xp: $xp, ')
          ..write('bestCombo: $bestCombo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    lessonId,
    startedAt,
    finishedAt,
    questions,
    correct,
    xp,
    bestCombo,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionRow &&
          other.id == this.id &&
          other.lessonId == this.lessonId &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt &&
          other.questions == this.questions &&
          other.correct == this.correct &&
          other.xp == this.xp &&
          other.bestCombo == this.bestCombo);
}

class SessionsCompanion extends UpdateCompanion<SessionRow> {
  final Value<int> id;
  final Value<String?> lessonId;
  final Value<DateTime> startedAt;
  final Value<DateTime> finishedAt;
  final Value<int> questions;
  final Value<int> correct;
  final Value<int> xp;
  final Value<int> bestCombo;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.lessonId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.questions = const Value.absent(),
    this.correct = const Value.absent(),
    this.xp = const Value.absent(),
    this.bestCombo = const Value.absent(),
  });
  SessionsCompanion.insert({
    this.id = const Value.absent(),
    this.lessonId = const Value.absent(),
    required DateTime startedAt,
    required DateTime finishedAt,
    required int questions,
    required int correct,
    required int xp,
    required int bestCombo,
  }) : startedAt = Value(startedAt),
       finishedAt = Value(finishedAt),
       questions = Value(questions),
       correct = Value(correct),
       xp = Value(xp),
       bestCombo = Value(bestCombo);
  static Insertable<SessionRow> custom({
    Expression<int>? id,
    Expression<String>? lessonId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? finishedAt,
    Expression<int>? questions,
    Expression<int>? correct,
    Expression<int>? xp,
    Expression<int>? bestCombo,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lessonId != null) 'lesson_id': lessonId,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (questions != null) 'questions': questions,
      if (correct != null) 'correct': correct,
      if (xp != null) 'xp': xp,
      if (bestCombo != null) 'best_combo': bestCombo,
    });
  }

  SessionsCompanion copyWith({
    Value<int>? id,
    Value<String?>? lessonId,
    Value<DateTime>? startedAt,
    Value<DateTime>? finishedAt,
    Value<int>? questions,
    Value<int>? correct,
    Value<int>? xp,
    Value<int>? bestCombo,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      questions: questions ?? this.questions,
      correct: correct ?? this.correct,
      xp: xp ?? this.xp,
      bestCombo: bestCombo ?? this.bestCombo,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lessonId.present) {
      map['lesson_id'] = Variable<String>(lessonId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    if (questions.present) {
      map['questions'] = Variable<int>(questions.value);
    }
    if (correct.present) {
      map['correct'] = Variable<int>(correct.value);
    }
    if (xp.present) {
      map['xp'] = Variable<int>(xp.value);
    }
    if (bestCombo.present) {
      map['best_combo'] = Variable<int>(bestCombo.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('lessonId: $lessonId, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('questions: $questions, ')
          ..write('correct: $correct, ')
          ..write('xp: $xp, ')
          ..write('bestCombo: $bestCombo')
          ..write(')'))
        .toString();
  }
}

class $AnswersTable extends Answers with TableInfo<$AnswersTable, AnswerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnswersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _expectedMeta = const VerificationMeta(
    'expected',
  );
  @override
  late final GeneratedColumn<String> expected = GeneratedColumn<String>(
    'expected',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _givenMeta = const VerificationMeta('given');
  @override
  late final GeneratedColumn<String> given = GeneratedColumn<String>(
    'given',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _elapsedMsMeta = const VerificationMeta(
    'elapsedMs',
  );
  @override
  late final GeneratedColumn<int> elapsedMs = GeneratedColumn<int>(
    'elapsed_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _xpMeta = const VerificationMeta('xp');
  @override
  late final GeneratedColumn<int> xp = GeneratedColumn<int>(
    'xp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cardMeta = const VerificationMeta('card');
  @override
  late final GeneratedColumn<String> card = GeneratedColumn<String>(
    'card',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    expected,
    given,
    elapsedMs,
    xp,
    card,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'answers';
  @override
  VerificationContext validateIntegrity(
    Insertable<AnswerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('expected')) {
      context.handle(
        _expectedMeta,
        expected.isAcceptableOrUnknown(data['expected']!, _expectedMeta),
      );
    } else if (isInserting) {
      context.missing(_expectedMeta);
    }
    if (data.containsKey('given')) {
      context.handle(
        _givenMeta,
        given.isAcceptableOrUnknown(data['given']!, _givenMeta),
      );
    } else if (isInserting) {
      context.missing(_givenMeta);
    }
    if (data.containsKey('elapsed_ms')) {
      context.handle(
        _elapsedMsMeta,
        elapsedMs.isAcceptableOrUnknown(data['elapsed_ms']!, _elapsedMsMeta),
      );
    } else if (isInserting) {
      context.missing(_elapsedMsMeta);
    }
    if (data.containsKey('xp')) {
      context.handle(_xpMeta, xp.isAcceptableOrUnknown(data['xp']!, _xpMeta));
    } else if (isInserting) {
      context.missing(_xpMeta);
    }
    if (data.containsKey('card')) {
      context.handle(
        _cardMeta,
        card.isAcceptableOrUnknown(data['card']!, _cardMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AnswerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnswerRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      expected: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expected'],
      )!,
      given: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}given'],
      )!,
      elapsedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}elapsed_ms'],
      )!,
      xp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}xp'],
      )!,
      card: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card'],
      ),
    );
  }

  @override
  $AnswersTable createAlias(String alias) {
    return $AnswersTable(attachedDatabase, alias);
  }
}

class AnswerRow extends DataClass implements Insertable<AnswerRow> {
  final int id;
  final int sessionId;

  /// Bonne réponse et réponse donnée : nom d'un `DiatonicStep`, d'un
  /// `Beats` ou d'un `Marking`. Juste si les deux sont égales.
  final String expected;
  final String given;

  /// Temps de réponse, de l'affichage de la question au choix.
  final int elapsedMs;
  final int xp;

  /// Carte de révision de la question (voir `lib/review/card.dart`).
  /// `null` avant la v2 : ces réponses ne créent pas de carte.
  final String? card;
  const AnswerRow({
    required this.id,
    required this.sessionId,
    required this.expected,
    required this.given,
    required this.elapsedMs,
    required this.xp,
    this.card,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    map['expected'] = Variable<String>(expected);
    map['given'] = Variable<String>(given);
    map['elapsed_ms'] = Variable<int>(elapsedMs);
    map['xp'] = Variable<int>(xp);
    if (!nullToAbsent || card != null) {
      map['card'] = Variable<String>(card);
    }
    return map;
  }

  AnswersCompanion toCompanion(bool nullToAbsent) {
    return AnswersCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      expected: Value(expected),
      given: Value(given),
      elapsedMs: Value(elapsedMs),
      xp: Value(xp),
      card: card == null && nullToAbsent ? const Value.absent() : Value(card),
    );
  }

  factory AnswerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnswerRow(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      expected: serializer.fromJson<String>(json['expected']),
      given: serializer.fromJson<String>(json['given']),
      elapsedMs: serializer.fromJson<int>(json['elapsedMs']),
      xp: serializer.fromJson<int>(json['xp']),
      card: serializer.fromJson<String?>(json['card']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'expected': serializer.toJson<String>(expected),
      'given': serializer.toJson<String>(given),
      'elapsedMs': serializer.toJson<int>(elapsedMs),
      'xp': serializer.toJson<int>(xp),
      'card': serializer.toJson<String?>(card),
    };
  }

  AnswerRow copyWith({
    int? id,
    int? sessionId,
    String? expected,
    String? given,
    int? elapsedMs,
    int? xp,
    Value<String?> card = const Value.absent(),
  }) => AnswerRow(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    expected: expected ?? this.expected,
    given: given ?? this.given,
    elapsedMs: elapsedMs ?? this.elapsedMs,
    xp: xp ?? this.xp,
    card: card.present ? card.value : this.card,
  );
  AnswerRow copyWithCompanion(AnswersCompanion data) {
    return AnswerRow(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      expected: data.expected.present ? data.expected.value : this.expected,
      given: data.given.present ? data.given.value : this.given,
      elapsedMs: data.elapsedMs.present ? data.elapsedMs.value : this.elapsedMs,
      xp: data.xp.present ? data.xp.value : this.xp,
      card: data.card.present ? data.card.value : this.card,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnswerRow(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('expected: $expected, ')
          ..write('given: $given, ')
          ..write('elapsedMs: $elapsedMs, ')
          ..write('xp: $xp, ')
          ..write('card: $card')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sessionId, expected, given, elapsedMs, xp, card);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnswerRow &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.expected == this.expected &&
          other.given == this.given &&
          other.elapsedMs == this.elapsedMs &&
          other.xp == this.xp &&
          other.card == this.card);
}

class AnswersCompanion extends UpdateCompanion<AnswerRow> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<String> expected;
  final Value<String> given;
  final Value<int> elapsedMs;
  final Value<int> xp;
  final Value<String?> card;
  const AnswersCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.expected = const Value.absent(),
    this.given = const Value.absent(),
    this.elapsedMs = const Value.absent(),
    this.xp = const Value.absent(),
    this.card = const Value.absent(),
  });
  AnswersCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required String expected,
    required String given,
    required int elapsedMs,
    required int xp,
    this.card = const Value.absent(),
  }) : sessionId = Value(sessionId),
       expected = Value(expected),
       given = Value(given),
       elapsedMs = Value(elapsedMs),
       xp = Value(xp);
  static Insertable<AnswerRow> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<String>? expected,
    Expression<String>? given,
    Expression<int>? elapsedMs,
    Expression<int>? xp,
    Expression<String>? card,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (expected != null) 'expected': expected,
      if (given != null) 'given': given,
      if (elapsedMs != null) 'elapsed_ms': elapsedMs,
      if (xp != null) 'xp': xp,
      if (card != null) 'card': card,
    });
  }

  AnswersCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionId,
    Value<String>? expected,
    Value<String>? given,
    Value<int>? elapsedMs,
    Value<int>? xp,
    Value<String?>? card,
  }) {
    return AnswersCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      expected: expected ?? this.expected,
      given: given ?? this.given,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      xp: xp ?? this.xp,
      card: card ?? this.card,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (expected.present) {
      map['expected'] = Variable<String>(expected.value);
    }
    if (given.present) {
      map['given'] = Variable<String>(given.value);
    }
    if (elapsedMs.present) {
      map['elapsed_ms'] = Variable<int>(elapsedMs.value);
    }
    if (xp.present) {
      map['xp'] = Variable<int>(xp.value);
    }
    if (card.present) {
      map['card'] = Variable<String>(card.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnswersCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('expected: $expected, ')
          ..write('given: $given, ')
          ..write('elapsedMs: $elapsedMs, ')
          ..write('xp: $xp, ')
          ..write('card: $card')
          ..write(')'))
        .toString();
  }
}

class $TheoryTable extends Theory with TableInfo<$TheoryTable, TheoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TheoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _lessonIdMeta = const VerificationMeta(
    'lessonId',
  );
  @override
  late final GeneratedColumn<String> lessonId = GeneratedColumn<String>(
    'lesson_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
    'page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _readMeta = const VerificationMeta('read');
  @override
  late final GeneratedColumn<bool> read = GeneratedColumn<bool>(
    'read',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("read" IN (0, 1))',
    ),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [lessonId, page, read, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'theory';
  @override
  VerificationContext validateIntegrity(
    Insertable<TheoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('lesson_id')) {
      context.handle(
        _lessonIdMeta,
        lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lessonIdMeta);
    }
    if (data.containsKey('page')) {
      context.handle(
        _pageMeta,
        page.isAcceptableOrUnknown(data['page']!, _pageMeta),
      );
    } else if (isInserting) {
      context.missing(_pageMeta);
    }
    if (data.containsKey('read')) {
      context.handle(
        _readMeta,
        read.isAcceptableOrUnknown(data['read']!, _readMeta),
      );
    } else if (isInserting) {
      context.missing(_readMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {lessonId};
  @override
  TheoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TheoryRow(
      lessonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lesson_id'],
      )!,
      page: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page'],
      )!,
      read: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}read'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TheoryTable createAlias(String alias) {
    return $TheoryTable(attachedDatabase, alias);
  }
}

class TheoryRow extends DataClass implements Insertable<TheoryRow> {
  final String lessonId;

  /// Dernière page ouverte, à partir de 0.
  final int page;

  /// Vrai une fois la dernière page passée (« S'entraîner »).
  final bool read;
  final DateTime updatedAt;
  const TheoryRow({
    required this.lessonId,
    required this.page,
    required this.read,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['lesson_id'] = Variable<String>(lessonId);
    map['page'] = Variable<int>(page);
    map['read'] = Variable<bool>(read);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TheoryCompanion toCompanion(bool nullToAbsent) {
    return TheoryCompanion(
      lessonId: Value(lessonId),
      page: Value(page),
      read: Value(read),
      updatedAt: Value(updatedAt),
    );
  }

  factory TheoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TheoryRow(
      lessonId: serializer.fromJson<String>(json['lessonId']),
      page: serializer.fromJson<int>(json['page']),
      read: serializer.fromJson<bool>(json['read']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'lessonId': serializer.toJson<String>(lessonId),
      'page': serializer.toJson<int>(page),
      'read': serializer.toJson<bool>(read),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TheoryRow copyWith({
    String? lessonId,
    int? page,
    bool? read,
    DateTime? updatedAt,
  }) => TheoryRow(
    lessonId: lessonId ?? this.lessonId,
    page: page ?? this.page,
    read: read ?? this.read,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TheoryRow copyWithCompanion(TheoryCompanion data) {
    return TheoryRow(
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      page: data.page.present ? data.page.value : this.page,
      read: data.read.present ? data.read.value : this.read,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TheoryRow(')
          ..write('lessonId: $lessonId, ')
          ..write('page: $page, ')
          ..write('read: $read, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(lessonId, page, read, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TheoryRow &&
          other.lessonId == this.lessonId &&
          other.page == this.page &&
          other.read == this.read &&
          other.updatedAt == this.updatedAt);
}

class TheoryCompanion extends UpdateCompanion<TheoryRow> {
  final Value<String> lessonId;
  final Value<int> page;
  final Value<bool> read;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TheoryCompanion({
    this.lessonId = const Value.absent(),
    this.page = const Value.absent(),
    this.read = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TheoryCompanion.insert({
    required String lessonId,
    required int page,
    required bool read,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : lessonId = Value(lessonId),
       page = Value(page),
       read = Value(read),
       updatedAt = Value(updatedAt);
  static Insertable<TheoryRow> custom({
    Expression<String>? lessonId,
    Expression<int>? page,
    Expression<bool>? read,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (lessonId != null) 'lesson_id': lessonId,
      if (page != null) 'page': page,
      if (read != null) 'read': read,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TheoryCompanion copyWith({
    Value<String>? lessonId,
    Value<int>? page,
    Value<bool>? read,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TheoryCompanion(
      lessonId: lessonId ?? this.lessonId,
      page: page ?? this.page,
      read: read ?? this.read,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (lessonId.present) {
      map['lesson_id'] = Variable<String>(lessonId.value);
    }
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (read.present) {
      map['read'] = Variable<bool>(read.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TheoryCompanion(')
          ..write('lessonId: $lessonId, ')
          ..write('page: $page, ')
          ..write('read: $read, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MasteredSkillsTable extends MasteredSkills
    with TableInfo<$MasteredSkillsTable, MasteredSkillRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MasteredSkillsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _skillIdMeta = const VerificationMeta(
    'skillId',
  );
  @override
  late final GeneratedColumn<String> skillId = GeneratedColumn<String>(
    'skill_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _masteredAtMeta = const VerificationMeta(
    'masteredAt',
  );
  @override
  late final GeneratedColumn<DateTime> masteredAt = GeneratedColumn<DateTime>(
    'mastered_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [skillId, masteredAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mastered_skills';
  @override
  VerificationContext validateIntegrity(
    Insertable<MasteredSkillRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('skill_id')) {
      context.handle(
        _skillIdMeta,
        skillId.isAcceptableOrUnknown(data['skill_id']!, _skillIdMeta),
      );
    } else if (isInserting) {
      context.missing(_skillIdMeta);
    }
    if (data.containsKey('mastered_at')) {
      context.handle(
        _masteredAtMeta,
        masteredAt.isAcceptableOrUnknown(data['mastered_at']!, _masteredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_masteredAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {skillId};
  @override
  MasteredSkillRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MasteredSkillRow(
      skillId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}skill_id'],
      )!,
      masteredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}mastered_at'],
      )!,
    );
  }

  @override
  $MasteredSkillsTable createAlias(String alias) {
    return $MasteredSkillsTable(attachedDatabase, alias);
  }
}

class MasteredSkillRow extends DataClass
    implements Insertable<MasteredSkillRow> {
  final String skillId;

  /// Première fois que la maîtrise a atteint le seuil.
  final DateTime masteredAt;
  const MasteredSkillRow({required this.skillId, required this.masteredAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['skill_id'] = Variable<String>(skillId);
    map['mastered_at'] = Variable<DateTime>(masteredAt);
    return map;
  }

  MasteredSkillsCompanion toCompanion(bool nullToAbsent) {
    return MasteredSkillsCompanion(
      skillId: Value(skillId),
      masteredAt: Value(masteredAt),
    );
  }

  factory MasteredSkillRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MasteredSkillRow(
      skillId: serializer.fromJson<String>(json['skillId']),
      masteredAt: serializer.fromJson<DateTime>(json['masteredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'skillId': serializer.toJson<String>(skillId),
      'masteredAt': serializer.toJson<DateTime>(masteredAt),
    };
  }

  MasteredSkillRow copyWith({String? skillId, DateTime? masteredAt}) =>
      MasteredSkillRow(
        skillId: skillId ?? this.skillId,
        masteredAt: masteredAt ?? this.masteredAt,
      );
  MasteredSkillRow copyWithCompanion(MasteredSkillsCompanion data) {
    return MasteredSkillRow(
      skillId: data.skillId.present ? data.skillId.value : this.skillId,
      masteredAt: data.masteredAt.present
          ? data.masteredAt.value
          : this.masteredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MasteredSkillRow(')
          ..write('skillId: $skillId, ')
          ..write('masteredAt: $masteredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(skillId, masteredAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MasteredSkillRow &&
          other.skillId == this.skillId &&
          other.masteredAt == this.masteredAt);
}

class MasteredSkillsCompanion extends UpdateCompanion<MasteredSkillRow> {
  final Value<String> skillId;
  final Value<DateTime> masteredAt;
  final Value<int> rowid;
  const MasteredSkillsCompanion({
    this.skillId = const Value.absent(),
    this.masteredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MasteredSkillsCompanion.insert({
    required String skillId,
    required DateTime masteredAt,
    this.rowid = const Value.absent(),
  }) : skillId = Value(skillId),
       masteredAt = Value(masteredAt);
  static Insertable<MasteredSkillRow> custom({
    Expression<String>? skillId,
    Expression<DateTime>? masteredAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (skillId != null) 'skill_id': skillId,
      if (masteredAt != null) 'mastered_at': masteredAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MasteredSkillsCompanion copyWith({
    Value<String>? skillId,
    Value<DateTime>? masteredAt,
    Value<int>? rowid,
  }) {
    return MasteredSkillsCompanion(
      skillId: skillId ?? this.skillId,
      masteredAt: masteredAt ?? this.masteredAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (skillId.present) {
      map['skill_id'] = Variable<String>(skillId.value);
    }
    if (masteredAt.present) {
      map['mastered_at'] = Variable<DateTime>(masteredAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MasteredSkillsCompanion(')
          ..write('skillId: $skillId, ')
          ..write('masteredAt: $masteredAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$NobemolDatabase extends GeneratedDatabase {
  _$NobemolDatabase(QueryExecutor e) : super(e);
  $NobemolDatabaseManager get managers => $NobemolDatabaseManager(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $AnswersTable answers = $AnswersTable(this);
  late final $TheoryTable theory = $TheoryTable(this);
  late final $MasteredSkillsTable masteredSkills = $MasteredSkillsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sessions,
    answers,
    theory,
    masteredSkills,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('answers', kind: UpdateKind.delete)],
    ),
  ]);
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$SessionsTableCreateCompanionBuilder = SessionsCompanion Function({
  Value<int> id,
  Value<String?> lessonId,
  required DateTime startedAt,
  required DateTime finishedAt,
  required int questions,
  required int correct,
  required int xp,
  required int bestCombo,
});
typedef $$SessionsTableUpdateCompanionBuilder = SessionsCompanion Function({
  Value<int> id,
  Value<String?> lessonId,
  Value<DateTime> startedAt,
  Value<DateTime> finishedAt,
  Value<int> questions,
  Value<int> correct,
  Value<int> xp,
  Value<int> bestCombo,
});

final class $$SessionsTableReferences
    extends BaseReferences<_$NobemolDatabase, $SessionsTable, SessionRow> {
  $$SessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AnswersTable, List<AnswerRow>> _answersRefsTable(
    _$NobemolDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.answers,
    aliasName: 'sessions__id__answers__session_id',
  );

  $$AnswersTableProcessedTableManager get answersRefs {
    final manager = $$AnswersTableTableManager(
      $_db,
      $_db.answers,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_answersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SessionsTableFilterComposer
    extends Composer<_$NobemolDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get questions => $composableBuilder(
    column: $table.questions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correct => $composableBuilder(
    column: $table.correct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get xp => $composableBuilder(
    column: $table.xp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bestCombo => $composableBuilder(
    column: $table.bestCombo,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> answersRefs(
    Expression<bool> Function($$AnswersTableFilterComposer f) f,
  ) {
    final $$AnswersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.answers,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnswersTableFilterComposer(
            $db: $db,
            $table: $db.answers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableOrderingComposer
    extends Composer<_$NobemolDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get questions => $composableBuilder(
    column: $table.questions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correct => $composableBuilder(
    column: $table.correct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get xp => $composableBuilder(
    column: $table.xp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bestCombo => $composableBuilder(
    column: $table.bestCombo,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$NobemolDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get lessonId =>
      $composableBuilder(column: $table.lessonId, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get questions =>
      $composableBuilder(column: $table.questions, builder: (column) => column);

  GeneratedColumn<int> get correct =>
      $composableBuilder(column: $table.correct, builder: (column) => column);

  GeneratedColumn<int> get xp =>
      $composableBuilder(column: $table.xp, builder: (column) => column);

  GeneratedColumn<int> get bestCombo =>
      $composableBuilder(column: $table.bestCombo, builder: (column) => column);

  Expression<T> answersRefs<T extends Object>(
    Expression<T> Function($$AnswersTableAnnotationComposer a) f,
  ) {
    final $$AnswersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.answers,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnswersTableAnnotationComposer(
            $db: $db,
            $table: $db.answers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$NobemolDatabase,
          $SessionsTable,
          SessionRow,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (SessionRow, $$SessionsTableReferences),
          SessionRow,
          PrefetchHooks Function({bool answersRefs})
        > {
  $$SessionsTableTableManager(_$NobemolDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> lessonId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> finishedAt = const Value.absent(),
                Value<int> questions = const Value.absent(),
                Value<int> correct = const Value.absent(),
                Value<int> xp = const Value.absent(),
                Value<int> bestCombo = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                lessonId: lessonId,
                startedAt: startedAt,
                finishedAt: finishedAt,
                questions: questions,
                correct: correct,
                xp: xp,
                bestCombo: bestCombo,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> lessonId = const Value.absent(),
                required DateTime startedAt,
                required DateTime finishedAt,
                required int questions,
                required int correct,
                required int xp,
                required int bestCombo,
              }) => SessionsCompanion.insert(
                id: id,
                lessonId: lessonId,
                startedAt: startedAt,
                finishedAt: finishedAt,
                questions: questions,
                correct: correct,
                xp: xp,
                bestCombo: bestCombo,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SessionsTable, SessionRow>(table),
                  $$SessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({answersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (answersRefs) db.answers],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (answersRefs)
                    await $_getPrefetchedDataByColumns<
                      SessionRow,
                      $SessionsTable,
                      AnswerRow,
                      $AnswersTable
                    >(
                      currentTable: table,
                      referencedTable: $$SessionsTableReferences
                          ._answersRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SessionsTableReferences(db, table, p0).answersRefs,
                      currentColumn: 'id',
                      referencedColumn: 'session_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$NobemolDatabase,
      $SessionsTable,
      SessionRow,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (SessionRow, $$SessionsTableReferences),
      SessionRow,
      PrefetchHooks Function({bool answersRefs})
    >;
typedef $$AnswersTableCreateCompanionBuilder = AnswersCompanion Function({
  Value<int> id,
  required int sessionId,
  required String expected,
  required String given,
  required int elapsedMs,
  required int xp,
  Value<String?> card,
});
typedef $$AnswersTableUpdateCompanionBuilder = AnswersCompanion Function({
  Value<int> id,
  Value<int> sessionId,
  Value<String> expected,
  Value<String> given,
  Value<int> elapsedMs,
  Value<int> xp,
  Value<String?> card,
});

final class $$AnswersTableReferences
    extends BaseReferences<_$NobemolDatabase, $AnswersTable, AnswerRow> {
  $$AnswersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SessionsTable _sessionIdTable(_$NobemolDatabase db) =>
      db.sessions.createAlias('answers__session_id__sessions__id');

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AnswersTableFilterComposer
    extends Composer<_$NobemolDatabase, $AnswersTable> {
  $$AnswersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get expected => $composableBuilder(
    column: $table.expected,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get given => $composableBuilder(
    column: $table.given,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get elapsedMs => $composableBuilder(
    column: $table.elapsedMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get xp => $composableBuilder(
    column: $table.xp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get card => $composableBuilder(
    column: $table.card,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnswersTableOrderingComposer
    extends Composer<_$NobemolDatabase, $AnswersTable> {
  $$AnswersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get expected => $composableBuilder(
    column: $table.expected,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get given => $composableBuilder(
    column: $table.given,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get elapsedMs => $composableBuilder(
    column: $table.elapsedMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get xp => $composableBuilder(
    column: $table.xp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get card => $composableBuilder(
    column: $table.card,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnswersTableAnnotationComposer
    extends Composer<_$NobemolDatabase, $AnswersTable> {
  $$AnswersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get expected =>
      $composableBuilder(column: $table.expected, builder: (column) => column);

  GeneratedColumn<String> get given =>
      $composableBuilder(column: $table.given, builder: (column) => column);

  GeneratedColumn<int> get elapsedMs =>
      $composableBuilder(column: $table.elapsedMs, builder: (column) => column);

  GeneratedColumn<int> get xp =>
      $composableBuilder(column: $table.xp, builder: (column) => column);

  GeneratedColumn<String> get card =>
      $composableBuilder(column: $table.card, builder: (column) => column);

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnswersTableTableManager
    extends
        RootTableManager<
          _$NobemolDatabase,
          $AnswersTable,
          AnswerRow,
          $$AnswersTableFilterComposer,
          $$AnswersTableOrderingComposer,
          $$AnswersTableAnnotationComposer,
          $$AnswersTableCreateCompanionBuilder,
          $$AnswersTableUpdateCompanionBuilder,
          (AnswerRow, $$AnswersTableReferences),
          AnswerRow,
          PrefetchHooks Function({bool sessionId})
        > {
  $$AnswersTableTableManager(_$NobemolDatabase db, $AnswersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnswersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnswersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnswersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<String> expected = const Value.absent(),
                Value<String> given = const Value.absent(),
                Value<int> elapsedMs = const Value.absent(),
                Value<int> xp = const Value.absent(),
                Value<String?> card = const Value.absent(),
              }) => AnswersCompanion(
                id: id,
                sessionId: sessionId,
                expected: expected,
                given: given,
                elapsedMs: elapsedMs,
                xp: xp,
                card: card,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionId,
                required String expected,
                required String given,
                required int elapsedMs,
                required int xp,
                Value<String?> card = const Value.absent(),
              }) => AnswersCompanion.insert(
                id: id,
                sessionId: sessionId,
                expected: expected,
                given: given,
                elapsedMs: elapsedMs,
                xp: xp,
                card: card,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AnswersTable, AnswerRow>(table),
                  $$AnswersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionId,
                        referencedTable: $$AnswersTableReferences
                            ._sessionIdTable(db),
                        referencedColumn: $$AnswersTableReferences
                            ._sessionIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AnswersTableProcessedTableManager =
    ProcessedTableManager<
      _$NobemolDatabase,
      $AnswersTable,
      AnswerRow,
      $$AnswersTableFilterComposer,
      $$AnswersTableOrderingComposer,
      $$AnswersTableAnnotationComposer,
      $$AnswersTableCreateCompanionBuilder,
      $$AnswersTableUpdateCompanionBuilder,
      (AnswerRow, $$AnswersTableReferences),
      AnswerRow,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$TheoryTableCreateCompanionBuilder = TheoryCompanion Function({
  required String lessonId,
  required int page,
  required bool read,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$TheoryTableUpdateCompanionBuilder = TheoryCompanion Function({
  Value<String> lessonId,
  Value<int> page,
  Value<bool> read,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$TheoryTableFilterComposer
    extends Composer<_$NobemolDatabase, $TheoryTable> {
  $$TheoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get read => $composableBuilder(
    column: $table.read,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TheoryTableOrderingComposer
    extends Composer<_$NobemolDatabase, $TheoryTable> {
  $$TheoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get read => $composableBuilder(
    column: $table.read,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TheoryTableAnnotationComposer
    extends Composer<_$NobemolDatabase, $TheoryTable> {
  $$TheoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get lessonId =>
      $composableBuilder(column: $table.lessonId, builder: (column) => column);

  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<bool> get read =>
      $composableBuilder(column: $table.read, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TheoryTableTableManager
    extends
        RootTableManager<
          _$NobemolDatabase,
          $TheoryTable,
          TheoryRow,
          $$TheoryTableFilterComposer,
          $$TheoryTableOrderingComposer,
          $$TheoryTableAnnotationComposer,
          $$TheoryTableCreateCompanionBuilder,
          $$TheoryTableUpdateCompanionBuilder,
          (
            TheoryRow,
            BaseReferences<_$NobemolDatabase, $TheoryTable, TheoryRow>,
          ),
          TheoryRow,
          PrefetchHooks Function()
        > {
  $$TheoryTableTableManager(_$NobemolDatabase db, $TheoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TheoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TheoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TheoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> lessonId = const Value.absent(),
                Value<int> page = const Value.absent(),
                Value<bool> read = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TheoryCompanion(
                lessonId: lessonId,
                page: page,
                read: read,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String lessonId,
                required int page,
                required bool read,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => TheoryCompanion.insert(
                lessonId: lessonId,
                page: page,
                read: read,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TheoryTable, TheoryRow>(table),
                  BaseReferences<_$NobemolDatabase, $TheoryTable, TheoryRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TheoryTableProcessedTableManager =
    ProcessedTableManager<
      _$NobemolDatabase,
      $TheoryTable,
      TheoryRow,
      $$TheoryTableFilterComposer,
      $$TheoryTableOrderingComposer,
      $$TheoryTableAnnotationComposer,
      $$TheoryTableCreateCompanionBuilder,
      $$TheoryTableUpdateCompanionBuilder,
      (TheoryRow, BaseReferences<_$NobemolDatabase, $TheoryTable, TheoryRow>),
      TheoryRow,
      PrefetchHooks Function()
    >;
typedef $$MasteredSkillsTableCreateCompanionBuilder =
    MasteredSkillsCompanion Function({
      required String skillId,
      required DateTime masteredAt,
      Value<int> rowid,
    });
typedef $$MasteredSkillsTableUpdateCompanionBuilder =
    MasteredSkillsCompanion Function({
      Value<String> skillId,
      Value<DateTime> masteredAt,
      Value<int> rowid,
    });

class $$MasteredSkillsTableFilterComposer
    extends Composer<_$NobemolDatabase, $MasteredSkillsTable> {
  $$MasteredSkillsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get skillId => $composableBuilder(
    column: $table.skillId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get masteredAt => $composableBuilder(
    column: $table.masteredAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MasteredSkillsTableOrderingComposer
    extends Composer<_$NobemolDatabase, $MasteredSkillsTable> {
  $$MasteredSkillsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get skillId => $composableBuilder(
    column: $table.skillId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get masteredAt => $composableBuilder(
    column: $table.masteredAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MasteredSkillsTableAnnotationComposer
    extends Composer<_$NobemolDatabase, $MasteredSkillsTable> {
  $$MasteredSkillsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get skillId =>
      $composableBuilder(column: $table.skillId, builder: (column) => column);

  GeneratedColumn<DateTime> get masteredAt => $composableBuilder(
    column: $table.masteredAt,
    builder: (column) => column,
  );
}

class $$MasteredSkillsTableTableManager
    extends
        RootTableManager<
          _$NobemolDatabase,
          $MasteredSkillsTable,
          MasteredSkillRow,
          $$MasteredSkillsTableFilterComposer,
          $$MasteredSkillsTableOrderingComposer,
          $$MasteredSkillsTableAnnotationComposer,
          $$MasteredSkillsTableCreateCompanionBuilder,
          $$MasteredSkillsTableUpdateCompanionBuilder,
          (
            MasteredSkillRow,
            BaseReferences<
              _$NobemolDatabase,
              $MasteredSkillsTable,
              MasteredSkillRow
            >,
          ),
          MasteredSkillRow,
          PrefetchHooks Function()
        > {
  $$MasteredSkillsTableTableManager(
    _$NobemolDatabase db,
    $MasteredSkillsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MasteredSkillsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MasteredSkillsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MasteredSkillsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> skillId = const Value.absent(),
                Value<DateTime> masteredAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MasteredSkillsCompanion(
                skillId: skillId,
                masteredAt: masteredAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String skillId,
                required DateTime masteredAt,
                Value<int> rowid = const Value.absent(),
              }) => MasteredSkillsCompanion.insert(
                skillId: skillId,
                masteredAt: masteredAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MasteredSkillsTable, MasteredSkillRow>(table),
                  BaseReferences<
                    _$NobemolDatabase,
                    $MasteredSkillsTable,
                    MasteredSkillRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MasteredSkillsTableProcessedTableManager =
    ProcessedTableManager<
      _$NobemolDatabase,
      $MasteredSkillsTable,
      MasteredSkillRow,
      $$MasteredSkillsTableFilterComposer,
      $$MasteredSkillsTableOrderingComposer,
      $$MasteredSkillsTableAnnotationComposer,
      $$MasteredSkillsTableCreateCompanionBuilder,
      $$MasteredSkillsTableUpdateCompanionBuilder,
      (
        MasteredSkillRow,
        BaseReferences<
          _$NobemolDatabase,
          $MasteredSkillsTable,
          MasteredSkillRow
        >,
      ),
      MasteredSkillRow,
      PrefetchHooks Function()
    >;

class $NobemolDatabaseManager {
  final _$NobemolDatabase _db;
  $NobemolDatabaseManager(this._db);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$AnswersTableTableManager get answers =>
      $$AnswersTableTableManager(_db, _db.answers);
  $$TheoryTableTableManager get theory =>
      $$TheoryTableTableManager(_db, _db.theory);
  $$MasteredSkillsTableTableManager get masteredSkills =>
      $$MasteredSkillsTableTableManager(_db, _db.masteredSkills);
}
