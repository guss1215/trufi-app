// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get mapStandardOffline => 'Standard (offline)';

  @override
  String get mapStandardOfflineDesc => 'Standard offline map';

  @override
  String get mapLightOffline => 'Light (offline)';

  @override
  String get mapLightOfflineDesc => 'Light offline map';

  @override
  String get mapDarkOffline => 'Dark (offline)';

  @override
  String get mapDarkOfflineDesc => 'Dark offline map';

  @override
  String get mapColorfulOffline => 'Colorful (offline)';

  @override
  String get mapColorfulOfflineDesc => 'Colorful offline map';
}
