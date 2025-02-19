##############
# Base image #
##############
FROM debian:12 AS base

# set time zone
ARG TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# install build tools
RUN apt update && apt install -y \
    build-essential \
    git \
    curl \
    wget \
    autotools-dev \
    autoconf \
    autoconf-archive \
    automake \
    libtool \
    pkg-config \
    cmake

# install gstreamer
RUN apt install -y \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    libgstreamer-plugins-bad1.0-dev \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    gstreamer1.0-tools

# install lidar driver dependencies
RUN apt install -y \
    libpcl-dev \
    libboost-dev \
    libboost-system-dev

#################
# overlay image #
#################
FROM base AS overlay

# install libsodium
WORKDIR /tmp
RUN curl -OL https://download.libsodium.org/libsodium/releases/libsodium-1.0.20-stable.tar.gz \
    && tar -zxvf libsodium-1.0.20-stable.tar.gz \
    && cd libsodium-stable \
    && ./configure \
    && make -j10 \
    && make check \
    && make install

# install ZeroMQ
WORKDIR /tmp
RUN git clone https://github.com/zeromq/libzmq.git \
    && cd libzmq \
    && ./autogen.sh \
    && ./configure --with-libsodium \
    && make -j10 \
    && make install \
    && ldconfig

# install capnproto
WORKDIR /tmp
RUN curl -O https://capnproto.org/capnproto-c++-1.1.0.tar.gz \
    && tar zxf capnproto-c++-1.1.0.tar.gz \
    && cd capnproto-c++-1.1.0 \
    && ./configure \
    && make check \
    && make install

# install publisher
RUN mkdir -p /ws/build /app/check
WORKDIR /ws
COPY ./projs/publisher publisher
RUN cmake -S publisher/all -B build \
    && cmake --build build --config Release --target all \
    && ln -s /ws/build/standalone/TSKPubStandalong /app/publisher \
    && ln -s /ws/build/test/unit/TSKPubUnitTest /app/check/unit \
    && ln -s /ws/build/test/integration/TSKPubIntegrationTests /app/check/integration


#####################
# Development image #
#####################
FROM overlay AS dev

# install some tools
RUN apt install -y \
    expect \
    rsync \
    gdb \
    sudo \
    clang-format \
    python3-venv

# develop args
ARG USERNAME=devuser
ARG UID=1000
ARG GID=$UID

# create user
RUN groupadd --gid $GID $USERNAME \
    && useradd --uid ${GID} --gid ${UID} --create-home ${USERNAME} \
    && echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME} \
    && mkdir -p /home/${USERNAME} \
    && chown -R ${UID}:${GID} /home/${USERNAME} \
    && usermod -aG video ${USERNAME}

# add cmd alias
RUN echo "alias ll='ls -alhF'" >> /home/${USERNAME}/.bash_aliases

# set the user 
RUN chown -R ${UID}:${GID} /ws
USER ${USERNAME}
WORKDIR /ws
