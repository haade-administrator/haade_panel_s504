// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get minimizeAppTooltip => 'Minimize the application';

  @override
  String get appWillMinimize => 'The application will minimize';

  @override
  String get mqttTabletControlTitle => 'MQTT Tablet Control';

  @override
  String get mqttSettingsTitle => 'MQTT Settings';

  @override
  String get mqttSettingsSubtitle => 'Configure the broker connection';

  @override
  String get ledControlTitle => 'LED Control';

  @override
  String get ledControlSubtitle => 'Turn on/off and change the color';

  @override
  String get relaySwitchTitle => 'Relay Switches';

  @override
  String get relaySwitchSubtitle => 'Controls relay switches';

  @override
  String get ioButtonControlTitle => 'I/O Button';

  @override
  String get ioButtonControlSubtitle => 'Controls the in/out buttons';

  @override
  String get parameterInformationTitle => 'Settings and Information';

  @override
  String get parameterInformationSubtitle => 'Temperature, Humidity, and Brightness Sensors';

  @override
  String get temperature => 'Temperature';

  @override
  String get humidity => 'Humidity';

  @override
  String get luxErrorValue => 'Invalid lux value';

  @override
  String get luxDark => 'Dark';

  @override
  String get luxDim => 'Dim light';

  @override
  String get luxModerate => 'Moderate light';

  @override
  String get luxBright => 'Bright light';

  @override
  String get luxVeryBright => 'Very bright light';

  @override
  String get luxMeasuring => 'Measuring...';

  @override
  String get luxAmbientTitle => 'Ambient Brightness';
}
