// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get title => 'Haade Panel s504';

  @override
  String get minimizeAppTooltip => 'Minimiser l\'application';

  @override
  String get appWillMinimize => 'L\'application va se minimiser';

  @override
  String get updateLaunchFailed => 'Échec du lancement de la mise à jour';

  @override
  String get newVersionAvailable => 'Nouvelle version dispo';

  @override
  String get checkUpdateTooltip => 'Vérifier mise à jour';

  @override
  String get updateAvailableTitle => 'Mise à jour disponible';

  @override
  String get updateAvailableContent =>
      'Une nouvelle version de l\'application est disponible.\nSouhaitez-vous la télécharger ?';

  @override
  String get cancel => 'Annuler';

  @override
  String get download => 'Télécharger';

  @override
  String get noUpdateAvailable => 'Aucune mise à jour disponible';

  @override
  String get mqttSettingsTitle => 'Paramètres MQTT';

  @override
  String get mqttSettingsSubtitle => 'Configurer la connexion au broker';

  @override
  String get ledControlTitle => 'Contrôle LED & Capteurs';

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
  String get parameterInformationSubtitle =>
      'Capteurs de températures, humidités, luminosités';

  @override
  String get mqttSettings => 'Paramètres MQTT';

  @override
  String get brokerAddress => 'Adresse du broker';

  @override
  String get port => 'Port';

  @override
  String get username => 'Nom d’utilisateur';

  @override
  String get password => 'Mot de passe';

  @override
  String get sslConnection => 'Connexion SSL';

  @override
  String get saveAndConnect => 'Enregistrer et connecter';

  @override
  String get settingsSaved => 'Paramètres enregistrés';

  @override
  String get mqttInitError =>
      'Client MQTT non initialisé. Appelez d\'abord connect().';

  @override
  String get mqttConnected => 'Connecté au broker MQTT';

  @override
  String get mqttDisconnected => 'Déconnecté du broker MQTT';

  @override
  String get mqttAttempt => 'Tentative de reconnexion MQTT';

  @override
  String get mqttReconnectSuccess => 'Reconnexion réussie';

  @override
  String get mqttNewTentative => 'Nouvelle tentative dans 10s:';

  @override
  String get mqttConnectionError => 'Erreur de connexion MQTT';

  @override
  String get mqttAutoConnectionError => 'MQTT Connexion automatique échouée';

  @override
  String get mqttInitializedError =>
      'Client MQTT non initialisé. Impossible de publier sur';

  @override
  String get mqttConnectionState => 'Déconnecté proprement';

  @override
  String get fieldRequired => 'Champ obligatoire';

  @override
  String get invalidPort => 'Port invalide';

  @override
  String get ledColor => 'Couleur des LEDs';

  @override
  String get brightnessLabel => 'Luminosité';

  @override
  String get ledOnLabel => 'LED allumée';

  @override
  String get relayControl => 'Contrôle des relais';

  @override
  String get relay1Label => 'Relais 1 (IN1)';

  @override
  String get relay2Label => 'Relais 2 (IN2)';

  @override
  String get ioControlTitle => 'Contrôle IO (Entrées / Sorties)';

  @override
  String get io1Label => 'IO1 (Bouton 1)';

  @override
  String get io2Label => 'IO2 (Bouton 2)';

  @override
  String get modeOutput => 'Mode : Sortie (Poussoir)';

  @override
  String get modeInput => 'Mode : Entrée';

  @override
  String get active => 'ACTIF';

  @override
  String get inactive => 'INACTIF';

  @override
  String triggerIo(Object ioNumber) {
    return 'Déclencher IO$ioNumber';
  }

  @override
  String get notificationSwitch => 'Notification de commutation';

  @override
  String get notificationDescriptionSwitch =>
      'Notifier lorsque le commutateur change d\'état';

  @override
  String get notificationIo => 'Notification d\'E/S';

  @override
  String get notificationDescriptionIo =>
      'Notifier lorsque l\'état des E/S change';

  @override
  String get notificationLuminosity => 'Notification de luminosité';

  @override
  String get notificationDescriptionLuminosity =>
      'Notifier lorsque la luminosité change d\'état';

  @override
  String get notificationDefault => 'Notification par défaut';

  @override
  String get notificationDescriptionDefault =>
      'Notifier lorsque les valeurs par défaut et MQTT changent d\'état';

  @override
  String get version => 'Version';

  @override
  String get tempHumidity => 'Température/Humidité';

  @override
  String get brightness => 'Luminosité';

  @override
  String get sensorSettings => 'Paramètres & Infos';

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
