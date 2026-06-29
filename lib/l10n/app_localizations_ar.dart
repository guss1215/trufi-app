// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get mapStandardOffline => 'قياسي (دون اتصال)';

  @override
  String get mapStandardOfflineDesc => 'خريطة قياسية دون اتصال';

  @override
  String get mapLightOffline => 'فاتح (دون اتصال)';

  @override
  String get mapLightOfflineDesc => 'خريطة فاتحة دون اتصال';

  @override
  String get mapDarkOffline => 'داكن (دون اتصال)';

  @override
  String get mapDarkOfflineDesc => 'خريطة داكنة دون اتصال';

  @override
  String get mapColorfulOffline => 'ملوّن (دون اتصال)';

  @override
  String get mapColorfulOfflineDesc => 'خريطة ملوّنة دون اتصال';

  @override
  String get mapLightOnline => 'فاتح (متصل)';

  @override
  String get mapLightOnlineDesc => 'خريطة فاتحة متصلة';

  @override
  String get mapStandardOnline => 'قياسي (متصل)';

  @override
  String get mapStandardOnlineDesc => 'خريطة قياسية متصلة';

  @override
  String get mapDarkOnline => 'داكن (متصل)';

  @override
  String get mapDarkOnlineDesc => 'خريطة داكنة متصلة';

  @override
  String get mapColorfulOnline => 'ملوّن (متصل)';

  @override
  String get mapColorfulOnlineDesc => 'خريطة ملوّنة متصلة';
}
