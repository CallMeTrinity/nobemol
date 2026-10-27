import 'package:yaml/yaml.dart';

/// Erreur dans un fichier de contenu (leçon ou arbre de compétences).
class ContentException implements Exception {
  const ContentException(this.message, {this.line, this.column});

  /// Erreur située sur [node].
  ContentException.at(YamlNode node, this.message)
    : line = node.span.start.line + 1,
      column = node.span.start.column + 1;

  final String message;

  /// Ligne dans le fichier, base 1, `null` si inconnue.
  final int? line;

  /// Colonne dans le fichier, base 1, `null` si inconnue.
  final int? column;

  @override
  String toString() => switch ((line, column)) {
    (null, _) => message,
    (final line?, null) => 'ligne $line : $message',
    (final line?, final column?) => 'ligne $line, colonne $column : $message',
  };
}

/// Lit un document YAML, erreurs de syntaxe comprises.
YamlNode loadContent(String source) {
  try {
    return loadYamlNode(source);
  } on YamlException catch (e) {
    final start = e.span?.start;
    throw ContentException(
      e.message,
      line: start == null ? null : start.line + 1,
      column: start == null ? null : start.column + 1,
    );
  }
}

/// Table YAML lue strictement : clés inconnues refusées, types vérifiés,
/// erreurs situées dans le fichier.
class YamlFields {
  YamlFields._(this.map, this.path);

  /// Lit [node] comme une table aux clés [required] et [optional].
  /// [path] situe la table dans les messages (`theory[2]`).
  factory YamlFields.read(
    YamlNode node, {
    String path = '',
    required Set<String> required,
    Set<String> optional = const {},
  }) {
    if (node is! YamlMap) {
      throw ContentException.at(node, '${_prefix(path)}table attendue');
    }
    for (final key in node.nodes.keys.cast<YamlNode>()) {
      final name = key.value;
      if (!required.contains(name) && !optional.contains(name)) {
        final known = [...required, ...optional].join(', ');
        throw ContentException.at(
          key,
          '${_prefix(path)}champ « $name » inconnu (attendus : $known)',
        );
      }
    }
    for (final key in required) {
      if (!node.nodes.containsKey(key)) {
        throw ContentException.at(
          node,
          '${_prefix(path)}champ « $key » manquant',
        );
      }
    }
    return YamlFields._(node, path);
  }

  final YamlMap map;
  final String path;

  YamlNode? node(String key) => map.nodes[key];

  /// Chemin de [key] pour les messages : `theory[2].abc`.
  String name(String key) => path.isEmpty ? key : '$path.$key';

  ContentException error(YamlNode node, String message) =>
      ContentException.at(node, message);

  /// Texte non vide.
  String string(String key) {
    final node = this.node(key)!;
    final value = node.value;
    if (value is! String || value.trim().isEmpty) {
      throw error(node, '${name(key)} : texte attendu');
    }
    return value;
  }

  String? optionalString(String key) => node(key) == null ? null : string(key);

  int integer(String key, {required int min, required int max, int? or}) {
    final node = this.node(key);
    if (node == null && or != null) return or;
    final value = node!.value;
    if (value is! int || value < min || value > max) {
      throw error(node, '${name(key)} : entier de $min à $max attendu');
    }
    return value;
  }

  bool boolean(String key, {required bool or}) {
    final node = this.node(key);
    if (node == null) return or;
    final value = node.value;
    if (value is! bool) {
      throw error(node, '${name(key)} : true ou false attendu');
    }
    return value;
  }

  /// Liste non vide.
  YamlList list(String key) {
    final node = this.node(key)!;
    if (node is! YamlList || node.nodes.isEmpty) {
      throw error(node, '${name(key)} : liste non vide attendue');
    }
    return node;
  }

  /// Liste de textes, sans doublon.
  List<String> strings(String key) {
    final values = <String>[];
    for (final node in list(key).nodes) {
      final value = node.value;
      if (value is! String) throw error(node, '${name(key)} : texte attendu');
      if (values.contains(value)) {
        throw error(node, '${name(key)} : « $value » en double');
      }
      values.add(value);
    }
    return values;
  }
}

String _prefix(String path) => path.isEmpty ? '' : '$path : ';
