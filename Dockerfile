# Base stage
FROM --platform=linux/amd64 ubuntu:22.04 AS base

SHELL ["/bin/bash", "-c"]

ENV project=meeting-sdk-linux-sample
ENV cwd=/tmp/$project

WORKDIR $cwd

ARG DEBIAN_FRONTEND=noninteractive

#  Install Dependencies
RUN apt-get update  \
    && apt-get install -y \
    build-essential \
    ca-certificates \
    cmake \
    curl \
    gdb \
    git \
    gfortran \
    libopencv-dev \
    libdbus-1-3 \
    libgbm1 \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libglib2.0-dev \
    libssl-dev \
    libx11-dev \
    libx11-xcb1 \
    libxcb-image0 \
    libxcb-keysyms1 \
    libxcb-randr0 \
    libxcb-shape0 \
    libxcb-shm0 \
    libxcb-xfixes0 \
    libxcb-xtest0 \
    libgl1-mesa-dri \
    libxfixes3 \
    linux-libc-dev \
    pkgconf \
    tar \
    unzip \
    zip \
    # Install ALSA and Pulseaudio
    libasound2 libasound2-plugins alsa alsa-utils alsa-oss pulseaudio pulseaudio-utils \
    # Install http-server to serve frontend
    npm http-server -g

# Install Node.js and vcpkg
FROM base AS deps

RUN curl -fsSL https://deb.nodesource.com/setup_22.x -o nodesource_setup.sh \
    && bash nodesource_setup.sh \
    && apt-get install -y nodejs

ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

WORKDIR /opt
RUN git clone --depth 1 https://github.com/Microsoft/vcpkg.git \
    && ./vcpkg/bootstrap-vcpkg.sh -disableMetrics \
    && ln -s /opt/vcpkg/vcpkg /usr/local/bin/vcpkg \
    && vcpkg install vcpkg-cmake

# Add the frontend files and backend script (server.js)
COPY client/web /usr/src/app/client/web
COPY src/server.js /usr/src/app/server.js

# Set the working directory for running the bot
WORKDIR $cwd

# Serve frontend and run backend server
CMD http-server /usr/src/app/client/web -p 8080 & node /usr/src/app/server.js & ./bin/entry.sh

# Entry point
ENTRYPOINT ["/tini", "--", "./bin/entry.sh"]