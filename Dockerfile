# ========================
# Flutter + Android + Dart + Linux + Web
# ========================
FROM ubuntu:22.04

# ---------- ENV ----------
ENV DEBIAN_FRONTEND=noninteractive
ENV FLUTTER_HOME=/opt/flutter
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV PATH=$PATH:$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/emulator

# ---------- SYSTEM DEPENDENCIES ----------
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl unzip git wget zip xz-utils file \
    libglu1-mesa openjdk-17-jdk python3 python3-pip ca-certificates \
    cmake ninja-build pkg-config clang \
    lib32stdc++6 lib32z1 \
    wget gnupg \
    libgtk-3-dev \
    liblzma-dev \
    libstdc++-12-dev \
    libblkid-dev \
    android-tools-adb \
    liblzma5 \
    mesa-utils \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y locales
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# ---------- FLUTTER ----------
RUN git clone https://github.com/flutter/flutter.git -b stable $FLUTTER_HOME

# ---------- ANDROID SDK ----------
RUN mkdir -p $ANDROID_SDK_ROOT/cmdline-tools
RUN curl -sSL https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip -o /tmp/cmdline-tools.zip && \
    unzip -q /tmp/cmdline-tools.zip -d $ANDROID_SDK_ROOT/cmdline-tools && \
    mv $ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools $ANDROID_SDK_ROOT/cmdline-tools/latest && \
    rm /tmp/cmdline-tools.zip

# ---------- ANDROID LICENSES ----------
RUN yes | sdkmanager --sdk_root=$ANDROID_SDK_ROOT --licenses
RUN sdkmanager --sdk_root=$ANDROID_SDK_ROOT \
    "platform-tools" \
    "platforms;android-34" \
    "build-tools;34.0.0" \
    "ndk;27.0.12077973" \
    "cmake;3.22.1"

# ---------- FLUTTER CONFIG ----------
RUN flutter config --no-analytics
RUN flutter precache
RUN yes | flutter doctor --android-licenses
RUN flutter doctor -v

# ---------- CHROME POUR FLUTTER WEB ----------
RUN wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/chrome.deb \
    && apt-get update \
    && apt-get install -y /tmp/chrome.deb \
    && rm /tmp/chrome.deb

# Fix pour Flutter Web (détection de Chrome)
ENV CHROME_EXECUTABLE=/usr/bin/google-chrome-stable

# ---------- WORKSPACE ----------
WORKDIR /workspace

# ---------- INSTALL PROJECT DEPENDENCIES ----------
# Copier pubspec pour Docker cache
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get || true

# ---------- VOLUME ----------
VOLUME ["/workspace"]

# ---------- DEFAULT CMD ----------
CMD [ "bash" ]
