// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get minimizeAppTooltip => 'Minimiser l\'application';

  @override
  String get appWillMinimize => 'L\'application va se minimiser';

  @override
  String get mqttTabletControlTitle => 'Contrôle MQTT Tablette';

  @override
  String get mqttSettingsTitle => 'Paramètres MQTT';

  @override
  String get mqttSettingsSubtitle => 'Configurer la connexion au broker';

  @override
  String get ledControlTitle => 'Contrôle LEDs';

  @override
  String get ledControlSubtitle => 'Allumer/Éteindre et changer la couleur';

  @override
  String get relaySwitchTitle => 'Interrupteurs Relais';

  @override
  String get relaySwitchSubtitle => 'Contrôle les interrupteurs relais';

  @override
  String get ioButtonControlTitle => 'Bouton I/O';

  @override
  String get ioButtonControlSubtitle => 'Contrôle des boutons in/out';

  @override
  String get parameterInformationTitle => 'Paramètres et Informatons';

  @override
  String get parameterInformationSubtitle => 'Capteurs de températures, humidités, luminosités';

  @override
  String get temperature => 'Température';

  @override
  String get humidity => 'Humidité';

  @override
  String get luxErrorValue => 'Valeur de lux invalide';

  @override
  String get luxDark => 'Sombre';

  @override
  String get luxDim => 'Lumière légère';

  @override
  String get luxModerate => 'Lumière modérée';

  @override
  String get luxBright => 'Lumière forte';

  @override
  String get luxVeryBright => 'Très forte luminosité';

  @override
  String get luxMeasuring => 'Mesure en cours...';

  @override
  String get luxAmbientTitle => 'Luminosité Ambiante';
}
