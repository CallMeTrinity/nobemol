import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Polices embarquées et leur licence (SIL OFL), à côté des licences des
/// paquets que Flutter réunit seul. Affichées dans Réglages > À propos.
const _fonts = {
  'Bravura': 'packages/notation/fonts/OFL.txt',
  'Edwin': 'packages/notation/fonts/Edwin-OFL.txt',
  'Bricolage Grotesque': 'fonts/BricolageGrotesque-OFL.txt',
  'Instrument Sans': 'fonts/InstrumentSans-OFL.txt',
  'DM Mono': 'fonts/DMMono-OFL.txt',
};

void registerFontLicenses(AssetBundle bundle) {
  LicenseRegistry.addLicense(() async* {
    for (final MapEntry(key: font, value: path) in _fonts.entries) {
      yield LicenseEntryWithLineBreaks([font], await bundle.loadString(path));
    }
  });
}
