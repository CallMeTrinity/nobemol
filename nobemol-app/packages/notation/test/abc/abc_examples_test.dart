import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:notation/notation.dart';

import '../helpers/describe_system.dart';

/// Les fichiers d'exemple du sous-ensemble ABC (doc/abc.md) servent de
/// tests : chacun annonce en première ligne le résultat ou l'erreur attendus.
void main() {
  final expected = RegExp(r'^% attendu : (.*)$', multiLine: true);
  final expectedError = RegExp(
    r'^% erreur : (\d+):(\d+) (.+)$',
    multiLine: true,
  );

  List<File> examples(String folder) =>
      Directory('test/abc/$folder')
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.abc'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  String name(File file) => file.uri.pathSegments.last;

  group('exemples valides', () {
    for (final file in examples('valid')) {
      test(name(file), () {
        final source = file.readAsStringSync();
        final match = expected.firstMatch(source);
        expect(match, isNotNull, reason: 'ligne « % attendu : » manquante');
        expect(describeSystem(parseAbc(source)), match!.group(1));
      });
    }
  });

  group('exemples invalides', () {
    for (final file in examples('invalid')) {
      test(name(file), () {
        final source = file.readAsStringSync();
        final match = expectedError.firstMatch(source);
        expect(match, isNotNull, reason: 'ligne « % erreur : » manquante');
        expect(
          () => parseAbc(source),
          throwsA(
            isA<AbcException>()
                .having((e) => e.line, 'line', int.parse(match!.group(1)!))
                .having((e) => e.column, 'column', int.parse(match.group(2)!))
                .having((e) => e.message, 'message', contains(match.group(3))),
          ),
        );
      });
    }
  });
}
