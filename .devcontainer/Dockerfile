FROM ubuntu:latest

# https://docs.flutter.dev/get-started/install/linux/android?tab=vscode
# Install needed packages
RUN apt update -y && apt upgrade -y;
RUN apt install -y curl git unzip xz-utils zip libglu1-mesa wget

WORKDIR /workspaces

# Download and extract android studio
# https://github.com/Deadolus/android-studio-docker/blob/master/Dockerfile
ARG ANDROID_STUDIO_URL=https://redirector.gvt1.com/edgedl/android/studio/ide-zips/2022.3.1.20/android-studio-2022.3.1.20-linux.tar.gz
ARG ANDROID_STUDIO_VERSION=2022.3.1.20

RUN wget "$ANDROID_STUDIO_URL" -O android-studio.tar.gz
RUN tar xzvf android-studio.tar.gz
RUN rm android-studio.tar.gz

# Download and extract flutter
ARG FLUTTER_URL=https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.22.1-stable.tar.xz

RUN wget "$FLUTTER_URL" -O flutter.tar.xz 
RUN tar -xf flutter.tar.xz -C /usr/bin
RUN rm flutter.tar.xz

# Add flutter to the path
ENV PATH="${PATH}:/usr/bin/flutter/bin"

# Fix a git issues
RUN git config --global --add safe.directory /usr/bin/flutter

# Install some build tools for flutter
RUN apt install -y clang cmake ninja-build pkg-config 
RUN apt install -y libgtk-3-dev

ARG CLI_URL=https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip

RUN wget "$CLI_URL" -O cli.zip
RUN unzip cli.zip
RUN rm cli.zip

RUN apt install -y default-jre

# Add sdkmanager to the path
RUN mkdir -p sdk/cmdline-tools/latest
RUN cp -r cmdline-tools/ sdk/
ENV PATH="${PATH}:/workspaces/sdk/cmdline-tools/bin"

RUN yes | sdkmanager --sdk_root=sdk "platforms;android-34" "cmdline-tools;latest" "platform-tools" "build-tools;34.0.0"

RUN flutter config --android-sdk sdk/
RUN yes | flutter doctor --android-licenses

RUN flutter channel

# Install google chrome
# https://stackoverflow.com/questions/70955307/how-to-install-google-chrome-in-a-docker-container
RUN apt install -y gnupg
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \ 
  && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list
RUN apt update && apt-get -y install google-chrome-stable

RUN apt install sudo