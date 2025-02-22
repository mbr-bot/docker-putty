#
# putty Dockerfile
#
# https://github.com/jlesage/docker-putty
#

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.14-v3.5.8

# Docker image version is provided via build arg.
ARG DOCKER_IMAGE_VERSION=unknown

# Define software versions.
ARG PUTTY_VERSION=0.76
ARG YAD_VERSION=7.3

# Define software download URLs.
ARG PUTTY_URL=https://the.earth.li/~sgtatham/putty/${PUTTY_VERSION}/putty-${PUTTY_VERSION}.tar.gz
ARG YAD_URL=https://github.com/v1cont/yad/releases/download/v${YAD_VERSION}/yad-${YAD_VERSION}.tar.xz

# Define working directory.
WORKDIR /tmp

# Install PuTTY.
RUN \
    # Install packages needed by the build.
    add-pkg --virtual build-dependencies \
        build-base \
        curl \
        gtk+3.0-dev \
        && \
    # Set same default compilation flags as abuild.
    export CFLAGS="-Os -fomit-frame-pointer" && \
    export CXXFLAGS="$CFLAGS" && \
    export CPPFLAGS="$CFLAGS" && \
    export LDFLAGS="-Wl,--as-needed" && \
    # Download the PuTTY package.
    mkdir putty && \
    echo "Downloading PuTTY package..." && \
    curl -# -L ${PUTTY_URL} | tar xz --strip 1  -C putty && \
    # Compile PuTTY.
    cd putty && \
    ./configure \
        --prefix=/usr \
        && \
    make && make install && \
    strip \
        /usr/bin/plink \
        /usr/bin/pscp \
        /usr/bin/psftp \
        /usr/bin/psusan \
        /usr/bin/puttygen \
        /usr/bin/pageant \
        /usr/bin/pterm \
        /usr/bin/putty \
        /usr/bin/puttytel \
        && \
    cd .. && \
    # Cleanup.
    del-pkg build-dependencies && \
    rm -rf /tmp/* /tmp/.[!.]*

# Install YAD.
# NOTE: YAD is compiled manually because the version on the Alpine repository
#       pulls too much dependencies.
RUN \
    # Install packages needed by the build.
    add-pkg --virtual build-dependencies \
        build-base \
        curl \
        intltool \
        gtk+3.0-dev \
        && \
    # Set same default compilation flags as abuild.
    export CFLAGS="-Os -fomit-frame-pointer" && \
    export CXXFLAGS="$CFLAGS" && \
    export CPPFLAGS="$CFLAGS" && \
    export LDFLAGS="-Wl,--as-needed" && \
    # Download.
    mkdir yad && \
    echo "Downloading YAD package..." && \
    curl -# -L ${YAD_URL} | tar xJ --strip 1  -C yad && \
    # Compile.
    cd yad && \
    ./configure \
        --prefix=/usr \
        --enable-standalone \
        --disable-icon-browser \
        --disable-html \
        --disable-pfd \
        && \
    make && make install && \
    strip /usr/bin/yad && \
    cd .. && \
    # Cleanup.
    del-pkg build-dependencies && \
    rm -rf /tmp/* /tmp/.[!.]*

# Install dependencies.
RUN add-pkg \
        gtk+3.0 \
        adwaita-icon-theme

# Adjust the openbox config.
RUN \
    # Maximize only the main/initial window.
    sed-patch 's/<application type="normal">/<application type="normal" title="putty">/' \
        /etc/xdg/openbox/rc.xml  && \
    # Make sure popup windows are shown in the center.
    sed-patch '/<\/applications>/i\  <application title="PuTTY *">\n    <decor>no<\/decor>\n    <position force="no">\n      <x>center<\/x>\n      <y>center<\/y>\n    <\/position>\n  <\/application>' \
        /etc/xdg/openbox/rc.xml

# Generate and install favicons.
RUN \
    APP_ICON_URL=https://github.com/jlesage/docker-templates/raw/master/jlesage/images/putty-icon.png && \
    install_app_icon.sh "$APP_ICON_URL"

# Add files.
COPY rootfs/ /

# Set environment variables.
ENV APP_NAME="PuTTY" \
    DISABLE_RESTART_SESSION_DIALOG_WINDOW=0 \
    KEEP_APP_RUNNING=1

# Define mountable directories.
VOLUME ["/config"]

# Metadata.
LABEL \
      org.label-schema.name="putty" \
      org.label-schema.description="Docker container for PuTTY" \
      org.label-schema.version="$DOCKER_IMAGE_VERSION" \
      org.label-schema.vcs-url="https://github.com/jlesage/docker-putty" \
      org.label-schema.schema-version="1.0"
