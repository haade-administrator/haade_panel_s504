// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'ELC SMT MQTT Tablet Control';

  @override
  String get minimizeAppTooltip => 'Minimize the application';

  @override
  String get appWillMinimize => 'The application will minimize';

  @override
  String get mqttSettingsTitle => 'MQTT Settings';

  @override
  String get mqttSettingsSubtitle => 'Configure the broker connection';

  @override
  String get ledControlTitle => 'LED & Sensor Control';

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
  String get mqttSettings => 'MQTT Settings';

  @override
  String get brokerAddress => 'Broker Address';

  @override
  String get port => 'Port';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get sslConnection => 'SSL Connection';

  @override
  String get saveAndConnect => 'Save and Connect';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get mqttConnected => 'Connected to MQTT broker';

  @override
  String get mqttConnectionError => 'MQTT connection error';

  @override
  String get fieldRequired => 'Field required';

  @override
  String get invalidPort => 'Invalid port';

  @override
  String get ledColor => 'LED Color';

  @override
  String get brightnessLabel => 'Brightness';

  @override
  String get ledOnLabel => 'LED On';

  @override
  String get relayControl => 'Relay Control';

  @override
  String get relay1Label => 'Relay 1 (IN1)';

  @override
  String get relay2Label => 'Relay 2 (IN2)';

  @override
  String get ioControlTitle => 'IO Control (Inputs/Outputs)';

  @override
  String get io1Label => 'IO1 (Button 1)';

  @override
  String get io2Label => 'IO2 (Button 2)';

  @override
  String get modeOutput => 'Mode: Output (Push)';

  @override
  String get modeInput => 'Mode: Input';

  @override
  String get active => 'ACTIVE';

  @override
  String get inactive => 'INACTIVE';

  @override
  String triggerIo(Object ioNumber) {
    return 'Trigger IO$ioNumber';
  }

  @override
  String get sensorSettings => 'Sensor Settings';

  @override
  String get tempHumidity => 'Temp/Humidity';

  @override
  String get brightness => 'Brightness';

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
