# Base image avec Debian
FROM ubuntu:22.04

# Définitions d'environnement Flutter et Android
ENV FLUTTER_HOME=/opt/flutter
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV PATH="$PATH:$FLUTTER_HOME/bin:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/emulator"

# Variables pour accepter les licences
ENV ANDROID_ACCEPT_LICENSES="android-sdk-license-.+"

# Installer dépendances système
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    git \
    wget \
    zip \
    libglu1-mesa \
    openjdk-17-jdk \
    xz-utils \
    file \
    lib32stdc++6 \
    lib32z1 \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Installer Flutter stable
RUN git clone https://github.com/flutter/flutter.git -b stable $FLUTTER_HOME
RUN flutter doctor

# Installer Android SDK Command-line tools
RUN mkdir -p $ANDROID_SDK_ROOT/cmdline-tools
RUN curl -o sdk-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip && \
    unzip sdk-tools.zip -d $ANDROID_SDK_ROOT/cmdline-tools && \
    mv $ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools $ANDROID_SDK_ROOT/cmdline-tools/latest && \
    rm sdk-tools.zip

# Installer Android SDK platforms et build-tools nécessaires
RUN yes | sdkmanager --sdk_root=$ANDROID_SDK_ROOT --licenses
RUN sdkmanager --sdk_root=$ANDROID_SDK_ROOT "platform-tools" "platforms;android-33" "build-tools;33.0.2" "ndk;27.0.12077973"

# Configurer Flutter pour Android
RUN flutter doctor --android-licenses --yes
RUN flutter precache

# Vérification
RUN flutter doctor -v

# Définir le répertoire de travail
WORKDIR /app

# Expose le dossier /app pour monter ton projet Flutter
VOLUME ["/app"]

# Commande par défaut
CMD [ "bash" ]
