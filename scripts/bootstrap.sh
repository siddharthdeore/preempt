#!/usr/bin/env bash
# ==============================================================================
# Script: bootstrap.sh
# Description: One-click installer to fetch and set up all three RT-Kernel scripts.
# ==============================================================================

set -uo pipefail

# ANSI Color Codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

REAL_USER="${SUDO_USER:-$USER}"

if [ "${REAL_USER}" = "root" ]; then
    BUILD_DIR="/root/rt-kernel"
else
    BUILD_DIR="/home/${REAL_USER}/rt-kernel"
fi

# Base raw URL of your GitHub repository scripts directory
BASE_URL="https://raw.githubusercontent.com/siddharthdeore/preempt/refs/heads/master/scripts"

echo -e "${BLUE}======================================================================${NC}"
echo -e "${BLUE} INITIALIZING REAL-TIME KERNEL WORKSPACE BOOTSTRAPPER${NC}"
echo -e "${BLUE}======================================================================${NC}"
echo -e " Target user:      ${REAL_USER}"
echo -e " Workspace:        ${BUILD_DIR}"
echo -e "${BLUE}======================================================================${NC}"

# Create the workspace directory
echo -e "[VERBOSE] Setting up directory: ${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# Download scripts directly into the workspace
echo -e "[VERBOSE] Fetching scripts from GitHub..."

declare -a SCRIPTS=("01_install_deps.sh" "02_download_and_patch.sh" "03_compile_kernel.sh")

for script in "${SCRIPTS[@]}"; do
    echo -e "Downloading ${BLUE}${script}${NC}..."
    wget -q --show-progress -O "${BUILD_DIR}/${script}" "${BASE_URL}/${script}"
    if [ $? -eq 0 ]; then
        chmod +x "${BUILD_DIR}/${script}"
    else
        echo -e "${RED}[ERROR] Failed to download ${script}${NC}"
        exit 1
    fi
done

# Fix ownership so your regular user owns the scripts
if [ "${REAL_USER}" != "root" ]; then
    chown -R "${REAL_USER}:${REAL_USER}" "${BUILD_DIR}"
fi

echo -e "${BLUE}======================================================================${NC}"
echo -e "${GREEN} SUCCESS! All scripts are downloaded and marked executable.${NC}"
echo -e " You can find them in: ${BUILD_DIR}"
echo -e " Run them step-by-step using:"
echo -e "   1. ${YELLOW}${BUILD_DIR}/01_install_deps.sh${NC}"
echo -e "   2. ${YELLOW}${BUILD_DIR}/02_download_and_patch.sh${NC}"
echo -e "   3. ${YELLOW}${BUILD_DIR}/03_compile_kernel.sh${NC}"
echo -e "${BLUE}======================================================================${NC}"
