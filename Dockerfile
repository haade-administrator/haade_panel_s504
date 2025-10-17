# Base image
FROM ubuntu:22.04

# Variables d'environnement
ENV FLUTTER_HOME=/opt/flutter
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV PATH="$PATH:$FLUTTER_HOME/bin:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/emulator"

# Installer dépendances système
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl unzip git wget zip libglu1-mesa openjdk-17-jdk xz-utils file \
    lib32stdc++6 lib32z1 python3 python3-pip cmake \
    && rm -rf /var/lib/apt/lists/*

# Installer Flutter
RUN git clone https://github.com/flutter/flutter.git -b stable $FLUTTER_HOME

# Installer Android SDK command-line tools
RUN mkdir -p $ANDROID_SDK_ROOT/cmdline-tools
RUN curl -o sdk-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip && \
    unzip sdk-tools.zip -d $ANDROID_SDK_ROOT/cmdline-tools && \
    mv $ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools $ANDROID_SDK_ROOT/cmdline-tools/latest && \
    rm sdk-tools.zip

# Installer SDK/platform-tools/build-tools/NDK/CMake
RUN yes | sdkmanager --sdk_root=$ANDROID_SDK_ROOT --licenses
RUN sdkmanager --sdk_root=$ANDROID_SDK_ROOT "platform-tools" "platforms;android-33" "build-tools;33.0.2" "ndk;27.0.12077973" "cmake;3.22.1"

# Accepter licences Android
RUN yes | flutter doctor --android-licenses

# Préparer Flutter
RUN flutter precache
RUN flutter doctor -v

# Créer le dossier /app et le copier temporairement pour installer les packages
WORKDIR /app

# Copier seulement pubspec.* pour récupérer les packages dans l'image
# Cela permet le caching Docker pour éviter de refaire pub get à chaque build si pubspec n'a pas changé
COPY pubspec.yaml pubspec.lock* ./

# Installer les packages
RUN flutter pub get

# Volume pour le projet réel
VOLUME ["/app"]

# Commande par défaut
CMD [ "bash" ]

