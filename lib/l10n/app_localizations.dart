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

  /// No description provided for @mqttTabletControlTitle.
  ///
  /// In en, this message translates to:
  /// **'MQTT Tablet Control'**
  String get mqttTabletControlTitle;

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
  /// **'LED Control'**
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
