import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Haade Panel s504'**
  String get title;

  /// No description provided for @minimizeAppTooltip.
  ///
  /// In en, this message translates to:
  /// **'Minimize the application'**
  String get minimizeAppTooltip;

  /// No description provided for @appWillMinimize.
  ///
  /// In en, this message translates to:
  /// **'The application will minimize'**
  String get appWillMinimize;

  /// No description provided for @updateLaunchFailed.
  ///
  /// In en, this message translates to:
  /// **'Update launch failed'**
  String get updateLaunchFailed;

  /// No description provided for @newVersionAvailable.
  ///
  /// In en, this message translates to:
  /// **'New version available'**
  String get newVersionAvailable;

  /// No description provided for @checkUpdateTooltip.
  ///
  /// In en, this message translates to:
  /// **'Check for update'**
  String get checkUpdateTooltip;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailableTitle;

  /// No description provided for @updateAvailableContent.
  ///
  /// In en, this message translates to:
  /// **'A new version of the application is available. Would you like to download it?'**
  String get updateAvailableContent;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @noUpdateAvailable.
  ///
  /// In en, this message translates to:
  /// **'No update available'**
  String get noUpdateAvailable;

  /// No description provided for @mqttSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'MQTT Settings'**
  String get mqttSettingsTitle;

  /// No description provided for @mqttSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure the broker connection'**
  String get mqttSettingsSubtitle;

  /// No description provided for @ledControlTitle.
  ///
  /// In en, this message translates to:
  /// **'LED & Sensor Control'**
  String get ledControlTitle;

  /// No description provided for @ledControlSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turn on/off and change the color'**
  String get ledControlSubtitle;

  /// No description provided for @relaySwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'Relay Switches'**
  String get relaySwitchTitle;

  /// No description provided for @relaySwitchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Controls relay switches'**
  String get relaySwitchSubtitle;

  /// No description provided for @ioButtonControlTitle.
  ///
  /// In en, this message translates to:
  /// **'I/O Button'**
  String get ioButtonControlTitle;

  /// No description provided for @ioButtonControlSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Controls the in/out buttons'**
  String get ioButtonControlSubtitle;

  /// No description provided for @parameterInformationTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings and Information'**
  String get parameterInformationTitle;

  /// No description provided for @parameterInformationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Temperature, Humidity, and Brightness Sensors'**
  String get parameterInformationSubtitle;

  /// No description provided for @mqttSettings.
  ///
  /// In en, this message translates to:
  /// **'MQTT Settings'**
  String get mqttSettings;

  /// No description provided for @brokerAddress.
  ///
  /// In en, this message translates to:
  /// **'Broker Address'**
  String get brokerAddress;

  /// No description provided for @port.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get port;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @sslConnection.
  ///
  /// In en, this message translates to:
  /// **'SSL Connection'**
  String get sslConnection;

  /// No description provided for @saveAndConnect.
  ///
  /// In en, this message translates to:
  /// **'Save and Connect'**
  String get saveAndConnect;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// No description provided for @mqttConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected to MQTT broker'**
  String get mqttConnected;

  /// No description provided for @mqttConnectionError.
  ///
  /// In en, this message translates to:
  /// **'MQTT connection error'**
  String get mqttConnectionError;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Field required'**
  String get fieldRequired;

  /// No description provided for @invalidPort.
  ///
  /// In en, this message translates to:
  /// **'Invalid port'**
  String get invalidPort;

  /// No description provided for @ledColor.
  ///
  /// In en, this message translates to:
  /// **'LED Color'**
  String get ledColor;

  /// No description provided for @brightnessLabel.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get brightnessLabel;

  /// No description provided for @ledOnLabel.
  ///
  /// In en, this message translates to:
  /// **'LED On'**
  String get ledOnLabel;

  /// No description provided for @relayControl.
  ///
  /// In en, this message translates to:
  /// **'Relay Control'**
  String get relayControl;

  /// No description provided for @relay1Label.
  ///
  /// In en, this message translates to:
  /// **'Relay 1 (IN1)'**
  String get relay1Label;

  /// No description provided for @relay2Label.
  ///
  /// In en, this message translates to:
  /// **'Relay 2 (IN2)'**
  String get relay2Label;

  /// No description provided for @ioControlTitle.
  ///
  /// In en, this message translates to:
  /// **'IO Control (Inputs/Outputs)'**
  String get ioControlTitle;

  /// No description provided for @io1Label.
  ///
  /// In en, this message translates to:
  /// **'IO1 (Button 1)'**
  String get io1Label;

  /// No description provided for @io2Label.
  ///
  /// In en, this message translates to:
  /// **'IO2 (Button 2)'**
  String get io2Label;

  /// No description provided for @modeOutput.
  ///
  /// In en, this message translates to:
  /// **'Mode: Output (Push)'**
  String get modeOutput;

  /// No description provided for @modeInput.
  ///
  /// In en, this message translates to:
  /// **'Mode: Input'**
  String get modeInput;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'INACTIVE'**
  String get inactive;

  /// No description provided for @triggerIo.
  ///
  /// In en, this message translates to:
  /// **'Trigger IO{ioNumber}'**
  String triggerIo(Object ioNumber);

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @tempHumidity.
  ///
  /// In en, this message translates to:
  /// **'Temperature / Humidity'**
  String get tempHumidity;

  /// No description provided for @brightness.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get brightness;

  /// No description provided for @sensorSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings & Infos'**
  String get sensorSettings;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @humidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidity;

  /// No description provided for @luxErrorValue.
  ///
  /// In en, this message translates to:
  /// **'Invalid lux value'**
  String get luxErrorValue;

  /// No description provided for @luxDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get luxDark;

  /// No description provided for @luxDim.
  ///
  /// In en, this message translates to:
  /// **'Dim light'**
  String get luxDim;

  /// No description provided for @luxModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate light'**
  String get luxModerate;

  /// No description provided for @luxBright.
  ///
  /// In en, this message translates to:
  /// **'Bright light'**
  String get luxBright;

  /// No description provided for @luxVeryBright.
  ///
  /// In en, this message translates to:
  /// **'Very bright light'**
  String get luxVeryBright;

  /// No description provided for @luxMeasuring.
  ///
  /// In en, this message translates to:
  /// **'Measuring...'**
  String get luxMeasuring;

  /// No description provided for @luxAmbientTitle.
  ///
  /// In en, this message translates to:
  /// **'Ambient Brightness'**
  String get luxAmbientTitle;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'fr': return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
