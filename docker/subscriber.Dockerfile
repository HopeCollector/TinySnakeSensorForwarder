##############
# base image #
##############

FROM osrf/ros:noetic-desktop-full-focal AS base

# set deault shell
SHELL ["/bin/bash", "-c"]

# set time zone
ARG TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# install some tools
RUN apt update && apt install -y \
    git \
    curl \
    wget \
    python3-pip \
    ros-noetic-foxglove*

#################    
# Overlay image #
#################
FROM base AS overlay

RUN mkdir -p /ws/subscriber

WORKDIR /ws

COPY ./projs/subscriber subscriber

RUN pip install -r subscriber/requirements.txt

#####################
# Development image #
#####################
FROM overlay AS dev

# develop args
ARG USERNAME=devuser
ARG UID=1000
ARG GID=$UID

# create user
RUN apt install -y sudo \
    && groupadd --gid $GID $USERNAME \
    && useradd --uid ${GID} --gid ${UID} --create-home ${USERNAME} \
    && echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME} \
    && mkdir -p /home/${USERNAME} \
    && chown -R ${UID}:${GID} /home/${USERNAME} /ws

# add cmd alias
RUN echo "alias ll='ls -alhF'" >> /home/${USERNAME}/.bash_aliases

# set the user 
RUN chown -R ${UID}:${GID} /ws
USER ${USERNAME}

# set workdir
WORKDIR /ws