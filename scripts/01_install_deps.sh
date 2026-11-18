#!/usr/bin/env bash
# ==============================================================================
# Script: 01_install_deps.sh
# Description: Clean and optimize compilation dependencies for Ubuntu 24.04 LTS
#              Supports targeted arguments and interactive prompts.
# ==============================================================================

set -uo pipefail

# ANSI Color Codes for clean console feedback
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Strictly resolve the real user's home directory (even if running under sudo)
REAL_USER="${SUDO_USER:-$USER}"

# Target list of cleaned, verified minimal compilation packages
PACKAGES=(
    build-essential fakeroot debhelper g++ git cmake pkg-config
    autoconf automake libtool autogen autoconf-archive
    zstd lz4 cpio kmod bc gawk dwarves flex bison
    libelf-dev libssl-dev libnuma-dev libudev-dev libpci-dev
    libdw-dev zlib1g-dev libncurses-dev libpcre2-dev
    stress cpufrequtils
)

RUN_APT_UPDATE=false
RUN_APT_INSTALL=false
INTERACTIVE_MODE=true

# ==============================================================================
# Helper Functions
# ==============================================================================

show_usage() {
    echo -e "Usage: $0 [options]"
    echo -e "Options:"
    echo -e "  --all              Execute both update and dependency installation."
    echo -e "  --update           Execute only 'apt update'."
    echo -e "  --install          Execute only dependency installations."
    echo -e "  --help             Display this usage manual."
    echo -e "\nIf no arguments are passed, the script runs interactively step-by-step."
}

ask_user() {
    local prompt_msg="$1"
    local default_val="$2" # Y or N
    local response
    
    if [ "${INTERACTIVE_MODE}" = "false" ]; then
        return 0
    fi

    while true; do
        read -rp "$(echo -e "${YELLOW}${prompt_msg} [y/n] (Default: ${default_val}): ${NC}")" response
        response="${response:-$default_val}"
        case "${response}" in
            [Yy]* ) return 0 ;;
            [Nn]* ) return 1 ;;
            * ) echo -e "${RED}Please answer yes (y) or no (n).${NC}" ;;
        esac
    done
}

# ==============================================================================
# Argument Parsing
# ==============================================================================

if [ $# -gt 0 ]; then
    INTERACTIVE_MODE=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all)
                RUN_APT_UPDATE=true
                RUN_APT_INSTALL=true
                shift
                ;;
            --update)
                RUN_APT_UPDATE=true
                shift
                ;;
            --install)
                RUN_APT_INSTALL=true
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                echo -e "${RED}[ERROR] Invalid option: $1${NC}"
                show_usage
                exit 1
                ;;
        esac
    done
fi

# ==============================================================================
# Main Process Initiation
# ==============================================================================

echo -e "${BLUE}======================================================================${NC}"
echo -e "${BLUE} STARTING DEPENDENCY INSTALLATION WORKFLOW${NC}"
echo -e "${BLUE}======================================================================${NC}"
echo -e " Logged in user:      ${USER}"
echo -e " Target developer:    ${REAL_USER}"
echo -e " Interactive Mode:    ${INTERACTIVE_MODE}"
echo -e "${BLUE}======================================================================${NC}"

# ==============================================================================
# STEP 1: Update Package Lists
# ==============================================================================
if [ "${INTERACTIVE_MODE}" = "true" ]; then
    if ask_user "Step 1: Do you want to run apt-get update?" "Y"; then
        RUN_APT_UPDATE=true
    fi
fi

if [ "${RUN_APT_UPDATE}" = "true" ]; then
    echo -e "\n${BLUE}----------------------------------------------------------------------${NC}"
    echo -e " STEP 1: Updating Package Lists"
    echo -e "${BLUE}----------------------------------------------------------------------${NC}"
    sudo apt update -y
fi

# ==============================================================================
# STEP 2: Install Kernel Dependencies
# ==============================================================================
if [ "${INTERACTIVE_MODE}" = "true" ]; then
    if ask_user "Step 2: Do you want to install verified kernel compilation dependencies?" "Y"; then
        RUN_APT_INSTALL=true
    fi
fi

if [ "${RUN_APT_INSTALL}" = "true" ]; then
    echo -e "\n${BLUE}----------------------------------------------------------------------${NC}"
    echo -e " STEP 2: Installing Build Tools and Packages"
    echo -e "${BLUE}----------------------------------------------------------------------${NC}"
    sudo apt install -y "${PACKAGES[@]}"
    echo -e "${GREEN}[SUCCESS] All target dependencies have been processed.${NC}"
fi

echo -e "\n${BLUE}======================================================================${NC}"
echo -e "${GREEN} DEPENDENCY CONFIGURATION COMPLETED SUCCESSFULY!${NC}"
echo -e "${BLUE}======================================================================${NC}"
