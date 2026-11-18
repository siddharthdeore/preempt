#!/usr/bin/env bash
# ==============================================================================
# Script: 02_download_and_patch.sh
# Description: Download Kernel 7.2 source code and apply PREEMPT-RT patch.
#              Strictly enforces non-root user workspace with ANSI logging.
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

if [ "${REAL_USER}" = "root" ]; then
    BUILD_DIR="/root/rt-kernel"
else
    BUILD_DIR="/home/${REAL_USER}/rt-kernel"
fi

KERNEL_VER="7.2"
KERNEL_TAR="linux-${KERNEL_VER}.tar.xz"
KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v7.x/${KERNEL_TAR}"

RT_PATCH="patch-7.2-rt5.patch"
RT_PATCH_XZ="${RT_PATCH}.xz"
PATCH_URL="https://cdn.kernel.org/pub/linux/projects/rt/7.2/${RT_PATCH_XZ}"

echo -e "${BLUE}======================================================================${NC}"
echo -e "${BLUE} STARTING RT-KERNEL DOWNLOAD & PATCH WORKFLOW${NC}"
echo -e "${BLUE}======================================================================${NC}"
echo -e " Logged in user:      ${USER}"
echo -e " Target developer:    ${REAL_USER}"
echo -e " Absolute Workspace:  ${BUILD_DIR}"
echo -e "${BLUE}======================================================================${NC}"

# Ensure target directory exists and configure appropriate ownership permissions
echo -e "[VERBOSE] Creating workspace directory: ${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

if [ "${REAL_USER}" != "root" ]; then
    chown -R "${REAL_USER}:${REAL_USER}" "${BUILD_DIR}"
fi

cd "${BUILD_DIR}" || { echo -e "${RED}[ERROR] Failed to navigate to ${BUILD_DIR}${NC}"; exit 1; }
echo -e "[VERBOSE] Working directory successfully set to: $(pwd)"


# ==============================================================================
# 2. Kernel Source Download & Extraction
# ==============================================================================
echo -e "${BLUE}----------------------------------------------------------------------${NC}"
echo -e " STEP 1: Handling Kernel Source (${KERNEL_TAR})"
echo -e "${BLUE}----------------------------------------------------------------------${NC}"

if [ ! -f "${BUILD_DIR}/${KERNEL_TAR}" ]; then
    echo -e "[VERBOSE] ${KERNEL_TAR} not found in workspace. Pulling from server..."
    echo -e "[DOWNLOAD] ${KERNEL_URL}"
    wget --show-progress -O "${BUILD_DIR}/${KERNEL_TAR}" "${KERNEL_URL}"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[SUCCESS] Kernel source downloaded successfully.${NC}"
    else
        echo -e "${RED}[ERROR] Failed to download Kernel source. Check connection/DNS.${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}[SKIP] ${KERNEL_TAR} already exists in ${BUILD_DIR}. Skipping download.${NC}"
fi

# Extraction Phase
if [ ! -d "${BUILD_DIR}/linux-${KERNEL_VER}" ]; then
    echo -e "[VERBOSE] Extracting kernel sources to ${BUILD_DIR}/linux-${KERNEL_VER}..."
    tar -xvf "${BUILD_DIR}/${KERNEL_TAR}" -C "${BUILD_DIR}/"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[SUCCESS] Kernel source successfully extracted.${NC}"
    else
        echo -e "${RED}[ERROR] Extraction failed.${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}[SKIP] Directory linux-${KERNEL_VER} already exists. Skipping extraction.${NC}"
fi


# ==============================================================================
# 3. RT Patch Download & Decompression
# ==============================================================================
echo -e "${BLUE}----------------------------------------------------------------------${NC}"
echo -e " STEP 2: Handling PREEMPT-RT Patch"
echo -e "${BLUE}----------------------------------------------------------------------${NC}"

# Navigate into the kernel source tree for patching
cd "${BUILD_DIR}/linux-${KERNEL_VER}" || { echo -e "${RED}[ERROR] Failed to enter source directory${NC}"; exit 1; }
echo -e "[VERBOSE] Entered directory: $(pwd)"

if [ ! -f "${RT_PATCH}" ]; then
    echo -e "[VERBOSE] ${RT_PATCH} not found. Pulling zipped patch..."
    echo -e "[DOWNLOAD] ${PATCH_URL}"
    wget --show-progress -O "${RT_PATCH_XZ}" "${PATCH_URL}"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[SUCCESS] Zipped patch downloaded successfully.${NC}"
    else
        echo -e "${RED}[ERROR] Failed to download patch. Check your internet connection.${NC}"
        exit 1
    fi
    
    echo -e "[VERBOSE] Decompressing ${RT_PATCH_XZ}..."
    unxz -v -f "${RT_PATCH_XZ}"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[SUCCESS] Patch file decompressed successfully to $(pwd)/${RT_PATCH}${NC}"
    else
        echo -e "${RED}[ERROR] Decompression failed.${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}[SKIP] Decompressed ${RT_PATCH} already exists. Skipping download.${NC}"
fi


# ==============================================================================
# 4. Dry-run and Apply PREEMPT-RT Patch
# ==============================================================================
echo -e "${BLUE}----------------------------------------------------------------------${NC}"
echo -e " STEP 3: Patching Process"
echo -e "${BLUE}----------------------------------------------------------------------${NC}"

echo -e "[VERBOSE] Executing dry run of patch command to prevent tree corruption..."
if patch -p1 --dry-run < "${RT_PATCH}"; then
    echo -e "${GREEN}[SUCCESS] Dry run passed cleanly. Applying patch...${NC}"
    patch -p1 < "${RT_PATCH}"
    echo -e "${GREEN}[SUCCESS] PREEMPT-RT patch successfully applied to kernel!${NC}"
else
    echo -e "${YELLOW}[WARNING] Dry run failed. Checking if kernel is already patched...${NC}"
    # Reverse patch check to confirm if the patch is already applied
    if patch -p1 -R --dry-run --silent < "${RT_PATCH}" >/dev/null 2>&1; then
        echo -e "${YELLOW}[SKIP] Patch has already been applied previously. Nothing to do.${NC}"
    else
        echo -e "${RED}[ERROR] Patch dry run failed completely. Source tree is corrupt/mismatched.${NC}"
        exit 1
    fi
fi

# Ensure all created files and directories belong to standard user rather than root
if [ "${REAL_USER}" != "root" ]; then
    chown -R "${REAL_USER}:${REAL_USER}" "${BUILD_DIR}"
fi

echo -e "${BLUE}======================================================================${NC}"
echo -e "${GREEN} WORKFLOW COMPLETE!${NC}"
echo -e " Workspace:   ${BUILD_DIR}"
echo -e " Target tree: ${BUILD_DIR}/linux-${KERNEL_VER}"
echo -e "${BLUE}======================================================================${NC}"
