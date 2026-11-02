import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Polices (SIL OFL) et sons (CC-BY) embarqués, avec leur licence, à côté
/// des licences des paquets que Flutter réunit seul. Affichées dans
/// Réglages > À propos.
const _assets = {
  'Bravura': 'packages/notation/fonts/OFL.txt',
  'Edwin': 'packages/notation/fonts/Edwin-OFL.txt',
  'Bricolage Grotesque': 'fonts/BricolageGrotesque-OFL.txt',
  'Instrument Sans': 'fonts/InstrumentSans-OFL.txt',
  'DM Mono': 'fonts/DMMono-OFL.txt',
  'Salamander Grand Piano': 'assets/audio/piano/CREDITS.txt',
};

void registerAssetLicenses(AssetBundle bundle) {
  LicenseRegistry.addLicense(() async* {
    for (final MapEntry(key: name, value: path) in _assets.entries) {
      yield LicenseEntryWithLineBreaks([name], await bundle.loadString(path));
    }
  });
}
