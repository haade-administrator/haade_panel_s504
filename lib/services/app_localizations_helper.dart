import '../l10n/app_localizations.dart';

class AppLocalizationsHelper {
  static late AppLocalizations _localizations;

  static void setLocalizations(AppLocalizations loc) {
    _localizations = loc;
  }

  static AppLocalizations get loc => _localizations;
}