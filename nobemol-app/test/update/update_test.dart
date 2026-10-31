import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nobemol/settings/settings.dart';
import 'package:nobemol/update/update.dart';

void main() {
  /// GitHub qui répond [body] avec le code [status], et compte les appels.
  var calls = 0;
  MockClient github(Object? body, {int status = 200}) => MockClient((request) {
    calls++;
    expect(request.url, latestReleaseUri);
    return Future.value(http.Response(jsonEncode(body), status));
  });

  Map<String, Object?> release(String tag) => {
    'tag_name': tag,
    'html_url': 'https://github.com/CallMeTrinity/nobemol/releases/tag/$tag',
  };

  setUp(() => calls = 0);

  test('versions : avec ou sans v, comparées nombre par nombre', () {
    expect(Version.tryParse('v1.10.0')! > Version.tryParse('1.9.3')!, isTrue);
    expect(Version.tryParse('1.0.0')!.compareTo(const Version(1, 0, 0)), 0);
    for (final text in ['1.0', 'v1.0.0-beta', 'latest', '']) {
      expect(Version.tryParse(text), isNull, reason: text);
    }
  });

  test('dernière release : version et page', () async {
    final latest = await fetchLatestRelease(github(release('v1.2.0')));
    expect('${latest!.version}', '1.2.0');
    expect(latest.page.path, '/CallMeTrinity/nobemol/releases/tag/v1.2.0');
  });

  test('réponse inattendue : rien', () async {
    expect(
      await fetchLatestRelease(github({'message': 'Not Found'}, status: 404)),
      isNull,
    );
    expect(await fetchLatestRelease(github([])), isNull);
    expect(await fetchLatestRelease(github(release('nightly'))), isNull);
  });

  group('mise à jour', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    Future<Release?> check(
      http.Client client, {
      Version? installed = const Version(1, 0, 0),
      bool updateCheck = true,
    }) async {
      final container = ProviderContainer(
        overrides: [
          httpClientProvider.overrideWithValue(client),
          installedVersionProvider.overrideWith((ref) async => installed),
          settingsProvider.overrideWith(
            () => SettingsNotifier(
              SettingsStore(prefs),
              Settings(updateCheck: updateCheck),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container.read(updateProvider.future);
    }

    test('plus récente que l’appli : signalée', () async {
      expect((await check(github(release('v1.1.0'))))!.version.minor, 1);
    });

    test('la même ou plus ancienne : rien', () async {
      expect(await check(github(release('v1.0.0'))), isNull);
      expect(
        await check(
          github(release('v1.0.0')),
          installed: const Version(1, 2, 0),
        ),
        isNull,
      );
    });

    test('sans réseau : rien, sans erreur', () async {
      final offline = MockClient(
        (_) => throw http.ClientException('pas de réseau'),
      );
      expect(await check(offline), isNull);
    });

    test('réglage coupé : aucune requête', () async {
      expect(
        await check(github(release('v9.0.0')), updateCheck: false),
        isNull,
      );
      expect(calls, 0);
    });
  });
}
