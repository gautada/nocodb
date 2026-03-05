ARG UBUNTU_VERSION="latest"
FROM ubuntu:$UBUNTU_VERSION as build
ARG IMAGE_VERSION="0.10.0"

# Update and install required dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    software-properties-common \
    build-essential \
    golang \
    python3 \
    python3-pip \
    npm \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt

# Configure git and clone the repository
RUN git config --global advice.detachedHead false \
    && git config --global --add safe.directory /opt \
    && git clone https://github.com/nocodb/nocodb

WORKDIR /opt/nocodb

# Install additional dependencies
RUN apt-get update && apt-get install -y \
    libssl-dev \
    && npm install -g pnpm \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
