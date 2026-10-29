import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:nobemol/lessons/content.dart';
import 'package:nobemol/lessons/skill_tree.dart';
import 'package:nobemol/lessons/yaml_fields.dart';

void main() {
  const skills = '''
- id: a.base
  title: Base
- id: a.next
  title: Suite
  requires: [a.base]
''';

  String lesson(String id, {String skill = 'a.base', int level = 1}) =>
      '''
id: $id
title: $id
skills: [$skill]
level: $level
theory:
  - text: x
exercise:
  type: note-reading
  staff: treble
''';

  group('arbre de compétences', () {
    test('valide', () {
      final tree = parseSkills(skills);
      expect(tree.map((s) => s.id), ['a.base', 'a.next']);
      expect(tree.last.requires, ['a.base']);
    });

    test('prérequis déclaré plus bas : refusé, pas de cycle possible', () {
      const reversed = '''
- id: a.next
  title: Suite
  requires: [a.base]
- id: a.base
  title: Base
''';
      expect(
        () => parseSkills(reversed),
        throwsA(
          isA<ContentException>()
              .having((e) => e.line, 'line', 3)
              .having((e) => e.message, 'message', contains('plus haut')),
        ),
      );
    });

    test('doublon et id invalide', () {
      expect(
        () => parseSkills('$skills- id: a.base\n  title: Encore\n'),
        throwsA(isA<ContentException>()),
      );
      expect(
        () => parseSkills('- id: Note_Reading\n  title: x\n'),
        throwsA(isA<ContentException>()),
      );
    });
  });

  test('leçons rangées par compétence, niveau, puis id', () {
    final content = parseContent(
      skills: skills,
      lessons: {
        'assets/lessons/c.yaml': lesson('c', skill: 'a.next'),
        'assets/lessons/b.yaml': lesson('b', level: 2),
        'assets/lessons/a2.yaml': lesson('a2'),
        'assets/lessons/a1.yaml': lesson('a1'),
      },
    );
    expect(content.lessons.map((l) => l.id), ['a1', 'a2', 'b', 'c']);
    expect(content.lesson('b')!.level, 2);
    expect(content.lesson('absente'), isNull);
  });

  test('toutes les erreurs sont listées, situées dans leur fichier', () {
    expect(
      () => parseContent(
        skills: skills,
        lessons: {
          'assets/lessons/ok.yaml': lesson('ok'),
          'assets/lessons/bad-id.yaml': lesson('autre'),
          'assets/lessons/bad-skill.yaml': lesson('bad-skill', skill: 'z'),
        },
      ),
      throwsA(
        isA<ContentErrors>().having((e) => e.messages, 'messages', [
          startsWith('assets/lessons/bad-id.yaml:1:5: '),
          startsWith('assets/lessons/bad-skill.yaml:3:10: '),
        ]),
      ),
    );
  });

  test('prérequis sans leçon pour sa maîtrise : la suite resterait '
      'verrouillée', () {
    expect(
      () => parseContent(
        skills: skills,
        lessons: {'assets/lessons/c.yaml': lesson('c', skill: 'a.next')},
      ),
      throwsA(
        isA<ContentErrors>().having((e) => e.messages, 'messages', [
          allOf(startsWith('assets/skills.yaml: '), contains('« a.base »')),
        ]),
      ),
    );
  });

  test('le contenu embarqué est valide', () {
    final lessons = {
      for (final file in Directory(lessonsDir).listSync().whereType<File>())
        if (file.path.endsWith('.yaml')) file.path: file.readAsStringSync(),
    };
    final content = parseContent(
      skills: File(skillsPath).readAsStringSync(),
      lessons: lessons,
    );
    expect(content.lessons, isNotEmpty);
  });
}
