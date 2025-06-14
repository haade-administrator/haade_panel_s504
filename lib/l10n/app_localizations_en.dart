// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'Haade Panel s504';

  @override
  String get minimizeAppTooltip => 'Minimize the application';

  @override
  String get appWillMinimize => 'The application will minimize';

  @override
  String get updateLaunchFailed => 'Update launch failed';

  @override
  String get newVersionAvailable => 'New version available';

  @override
  String get checkUpdateTooltip => 'Check for update';

  @override
  String get updateAvailableTitle => 'Update available';

  @override
  String get updateAvailableContent => 'A new version of the application is available. Would you like to download it?';

  @override
  String get cancel => 'Cancel';

  @override
  String get download => 'Download';

  @override
  String get noUpdateAvailable => 'No update available';

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
  String get mqttDisconnected => 'Disconnected from MQTT broker';

  @override
  String get mqttAttempt => 'Attempting to reconnect MQTT';

  @override
  String get mqttReconnectSuccess => 'Reconnection successful';

  @override
  String get mqttNewTentative => 'New attempt in 10s:';

  @override
  String get mqttConnectionError => 'MQTT connection error';

  @override
  String get mqttAutoConnectionError => 'MQTT Auto-Connection Failed';

  @override
  String get mqttInitializedError => 'MQTT client not initialized. Cannot publish to';

  @override
  String get mqttConnectionState => 'Cleanly disconnected';

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
  String get version => 'Version';

  @override
  String get tempHumidity => 'Temperature / Humidity';

  @override
  String get brightness => 'Brightness';

  @override
  String get sensorSettings => 'Settings & Infos';

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
