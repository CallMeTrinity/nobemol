import 'dart:io';

import 'package:flutter/services.dart';

/// Charge Bravura dans le moteur de test, qui n'embarque aucune police.
///
/// À lancer depuis la racine du package (comportement de `flutter test`).
Future<void> loadBravura() async {
  final bytes = File('fonts/Bravura.otf').readAsBytesSync();
  final loader = FontLoader('packages/notation/Bravura')
    ..addFont(Future.value(ByteData.sublistView(bytes)));
  await loader.load();
}
