#!/usr/bin/env bash
# ==============================================================================
# Script: 01_install_deps.sh
# Description: Clean and optimize compilation dependencies for Ubuntu 24.04 LTS
# ==============================================================================

set -euo pipefail

echo "=== [STEP 1] Updating package indices..."
sudo apt update -y

echo "=== [STEP 1] Installing optimized compilation dependencies..."
sudo apt install -y \
    build-essential \
    fakeroot \
    debhelper \
    g++ \
    git \
    cmake \
    pkg-config \
    autoconf \
    automake \
    libtool \
    autogen \
    autoconf-archive \
    zstd \
    lz4 \
    cpio \
    kmod \
    bc \
    gawk \
    dwarves \
    flex \
    bison \
    libelf-dev \
    libssl-dev \
    libnuma-dev \
    libudev-dev \
    libpci-dev \
    libdw-dev \
    zlib1g-dev \
    libncurses-dev \
    libpcre2-dev \
    stress \
    cpufrequtils

echo "=== [STEP 1] Clean dependency setup complete!"
