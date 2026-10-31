import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import 'package:nobemol/settings/settings.dart';

/// Dernière release publiée (ni brouillon ni pré-version). Le repo est
/// public : pas de token, 60 requêtes par heure et par adresse IP.
final latestReleaseUri = Uri.parse(
  'https://api.github.com/repos/CallMeTrinity/nobemol/releases/latest',
);

/// Version `x.y.z` d'une release (`v1.2.0`) ou de l'appli (`1.2.0`).
class Version implements Comparable<Version> {
  const Version(this.major, this.minor, this.patch);

  final int major;
  final int minor;
  final int patch;

  /// `null` hors du format `x.y.z` (avec ou sans `v` devant, sans suffixe).
  static Version? tryParse(String text) {
    final match = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)$').firstMatch(text.trim());
    if (match == null) return null;
    return Version(
      int.parse(match[1]!),
      int.parse(match[2]!),
      int.parse(match[3]!),
    );
  }

  @override
  int compareTo(Version other) => switch (major.compareTo(other.major)) {
    0 => switch (minor.compareTo(other.minor)) {
      0 => patch.compareTo(other.patch),
      final order => order,
    },
    final order => order,
  };

  bool operator >(Version other) => compareTo(other) > 0;

  @override
  String toString() => '$major.$minor.$patch';
}

/// Une release GitHub : sa version et sa page (notes et APK).
class Release {
  const Release(this.version, this.page);

  final Version version;
  final Uri page;
}

/// La dernière release, `null` si la réponse ne se lit pas.
Future<Release?> fetchLatestRelease(http.Client client) async {
  final response = await client.get(
    latestReleaseUri,
    headers: {'Accept': 'application/vnd.github+json'},
  );
  if (response.statusCode != 200) return null;
  final json = jsonDecode(response.body);
  if (json is! Map<String, Object?>) return null;
  final (tag, page) = (json['tag_name'], json['html_url']);
  if (tag is! String || page is! String) return null;
  final version = Version.tryParse(tag);
  final uri = Uri.tryParse(page);
  if (version == null || uri == null) return null;
  return Release(version, uri);
}

/// Client HTTP, remplaçable en test.
final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

/// Version installée (`1.0.0`), lue dans l'APK.
final installedVersionProvider = FutureProvider<Version?>(
  (ref) async => Version.tryParse((await PackageInfo.fromPlatform()).version),
);

/// Release plus récente que l'appli, vérifiée une fois par lancement. Pas
/// de Play Store : c'est le seul moyen de l'apprendre. `null` sans réseau,
/// réglage coupé, ou appli à jour : rien à dire, jamais d'erreur.
final updateProvider = FutureProvider<Release?>((ref) async {
  if (!ref.watch(settingsProvider.select((s) => s.updateCheck))) return null;
  try {
    final installed = await ref.watch(installedVersionProvider.future);
    final latest = await fetchLatestRelease(ref.read(httpClientProvider));
    if (installed == null || latest == null) return null;
    return latest.version > installed ? latest : null;
  } on Exception {
    return null;
  }
});
