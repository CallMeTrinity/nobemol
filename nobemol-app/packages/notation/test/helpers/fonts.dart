import 'dart:io';

import 'package:flutter/services.dart';

/// Charge Bravura et Edwin dans le moteur de test, qui n'embarque aucune
/// police.
///
/// À lancer depuis la racine du package (comportement de `flutter test`).
Future<void> loadFonts() async {
  for (final (family, file) in [
    ('Bravura', 'fonts/Bravura.otf'),
    ('Edwin', 'fonts/Edwin-Italic.otf'),
  ]) {
    final bytes = File(file).readAsBytesSync();
    final loader = FontLoader('packages/notation/$family')
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  }
}
