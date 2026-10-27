import 'package:meta/meta.dart';

/// Erreur de lecture ABC, située dans le texte source.
@immutable
class AbcException implements Exception {
  /// Crée une erreur en [line], [column] (base 1).
  const new(this.message, {required this.line, required this.column});

  /// Message en français.
  final String message;

  /// Ligne, base 1.
  final int line;

  /// Colonne, base 1.
  final int column;

  @override
  String toString() => 'ligne $line, colonne $column : $message';
}
