#!/usr/bin/env bash
# ==============================================================================
# Script: 02_download_and_patch.sh
# Description: Download Kernel 7.2 source code and apply PREEMPT-RT patch.
#              Supports targeted arguments, interactive prompts, and overwrites.
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
PATCH_URL="https://cdn.kernel.org/pub/linux/kernel/projects/rt/7.2/older/${RT_PATCH_XZ}"

# Initialize operation flags (defaulting to false unless set by args)
RUN_DOWNLOAD_KERNEL=false
RUN_DOWNLOAD_PATCH=false
RUN_EXTRACT=false
RUN_PATCH=false
FORCE_OVERWRITE=false
INTERACTIVE_MODE=true

# ==============================================================================
# Helper Functions
# ==============================================================================

show_usage() {
    echo -e "Usage: $0 [options]"
    echo -e "Options:"
    echo -e "  --all              Execute all compilation steps sequentially."
    echo -e "  --download-kernel  Execute only the kernel source download step."
    echo -e "  --download-patch   Execute only the PREEMPT-RT patch download step."
    echo -e "  --extract          Execute only the kernel extraction step."
    echo -e "  --patch            Execute only the patch application step."
    echo -e "  --force            Overwrite existing files/directories without prompting."
    echo -e "  --help             Display this usage manual."
    echo -e "\nIf no step arguments are passed, the script runs interactively step-by-step."
}

# Prompt user for confirmation (Y/N)
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

# Setup workspace and permissions safely
setup_workspace() {
    echo -e "[VERBOSE] Checking workspace: ${BUILD_DIR}"
    if [ ! -d "${BUILD_DIR}" ]; then
        mkdir -p "${BUILD_DIR}"
    fi
    if [ "${REAL_USER}" != "root" ]; then
        chown -R "${REAL_USER}:${REAL_USER}" "${BUILD_DIR}"
    fi
}

# ==============================================================================
# Argument Parsing
# ==============================================================================

if [ $# -gt 0 ]; then
    INTERACTIVE_MODE=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all)
                RUN_DOWNLOAD_KERNEL=true
                RUN_DOWNLOAD_PATCH=true
                RUN_EXTRACT=true
                RUN_PATCH=true
                shift
                ;;
            --download-kernel)
                RUN_DOWNLOAD_KERNEL=true
                shift
                ;;
            --download-patch)
                RUN_DOWNLOAD_PATCH=true
                shift
                ;;
            --extract)
                RUN_EXTRACT=true
                shift
                ;;
            --patch)
                RUN_PATCH=true
                shift
                ;;
            --force)
                FORCE_OVERWRITE=true
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
echo -e "${BLUE} STARTING RT-KERNEL CONFIGURABLE WORKFLOW${NC}"
echo -e "${BLUE}======================================================================${NC}"
echo -e " Logged in user:      ${USER}"
echo -e " Target developer:    ${REAL_USER}"
echo -e " Absolute Workspace:  ${BUILD_DIR}"
echo -e " Interactive Mode:    ${INTERACTIVE_MODE}"
echo -e " Force Overwrite:     ${FORCE_OVERWRITE}"
echo -e "${BLUE}======================================================================${NC}"

setup_workspace

# ==============================================================================
# STEP 1: Download Kernel Source
# ==============================================================================
if [ "${INTERACTIVE_MODE}" = "true" ]; then
    if ask_user "Step 1: Do you want to check/download the Kernel 7.2 Source?" "Y"; then
        RUN_DOWNLOAD_KERNEL=true
    fi
fi

if [ "${RUN_DOWNLOAD_KERNEL}" = "true" ]; then
    echo -e "\n${BLUE}----------------------------------------------------------------------${NC}"
    echo -e " STEP 1: Handling Kernel Source Download"
    echo -e "${BLUE}----------------------------------------------------------------------${NC}"
    
    cd "${BUILD_DIR}"
    
    if [ -f "${KERNEL_TAR}" ]; then
        echo -e "${YELLOW}[WARNING] Target archive ${KERNEL_TAR} already exists.${NC}"
        if [ "${FORCE_OVERWRITE}" = "true" ] || ask_user "Do you want to overwrite and re-download it?" "N"; then
            echo -e "[VERBOSE] Removing existing file: ${KERNEL_TAR}"
            rm -f "${KERNEL_TAR}"
            echo -e "[DOWNLOAD] Pulling: ${KERNEL_URL}"
            wget --show-progress -O "${KERNEL_TAR}" "${KERNEL_URL}"
        else
            echo -e "${GREEN}[SKIP] Keeping existing file.${NC}"
        fi
    else
        echo -e "[DOWNLOAD] Pulling: ${KERNEL_URL}"
        wget --show-progress -O "${KERNEL_TAR}" "${KERNEL_URL}"
    fi
fi

# ==============================================================================
# STEP 2: Extract Kernel Source
# ==============================================================================
if [ "${INTERACTIVE_MODE}" = "true" ]; then
    if ask_user "Step 2: Do you want to extract the Kernel Source archive?" "Y"; then
        RUN_EXTRACT=true
    fi
fi

if [ "${RUN_EXTRACT}" = "true" ]; then
    echo -e "\n${BLUE}----------------------------------------------------------------------${NC}"
    echo -e " STEP 2: Extracting Kernel Source"
    echo -e "${BLUE}----------------------------------------------------------------------${NC}"
    
    cd "${BUILD_DIR}"
    
    if [ ! -f "${KERNEL_TAR}" ]; then
        echo -e "${RED}[ERROR] Expected ${KERNEL_TAR} missing from workspace directory. Cannot extract.${NC}"
        exit 1
    fi

    if [ -d "linux-${KERNEL_VER}" ]; then
        echo -e "${YELLOW}[WARNING] Output directory linux-${KERNEL_VER} already exists.${NC}"
        if [ "${FORCE_OVERWRITE}" = "true" ] || ask_user "Do you want to clear the directory and re-extract?" "N"; then
            echo -e "[VERBOSE] Purging old kernel tree..."
            rm -rf "linux-${KERNEL_VER}"
            echo -e "[VERBOSE] Extracting kernel sources..."
            tar -xf "${KERNEL_TAR}" -C "${BUILD_DIR}/"
            echo -e "${GREEN}[SUCCESS] Source tree extracted.${NC}"
        else
            echo -e "${GREEN}[SKIP] Keeping existing tree.${NC}"
        fi
    else
        echo -e "[VERBOSE] Extracting kernel sources..."
        tar -xf "${KERNEL_TAR}" -C "${BUILD_DIR}/"
        echo -e "${GREEN}[SUCCESS] Source tree extracted successfully.${NC}"
    fi
fi

# ==============================================================================
# STEP 3: Download PREEMPT-RT Patch
# ==============================================================================
if [ "${INTERACTIVE_MODE}" = "true" ]; then
    if ask_user "Step 3: Do you want to check/download the PREEMPT-RT Patch?" "Y"; then
        RUN_DOWNLOAD_PATCH=true
    fi
fi

if [ "${RUN_DOWNLOAD_PATCH}" = "true" ]; then
    echo -e "\n${BLUE}----------------------------------------------------------------------${NC}"
    echo -e " STEP 3: Handling PREEMPT-RT Patch Download"
    echo -e "${BLUE}----------------------------------------------------------------------${NC}"
    
    TARGET_PATCH_DIR="${BUILD_DIR}/linux-${KERNEL_VER}"
    if [ ! -d "${TARGET_PATCH_DIR}" ]; then
        echo -e "${RED}[ERROR] Kernel directory ${TARGET_PATCH_DIR} does not exist. Run Step 2 (Extraction) first.${NC}"
        exit 1
    fi
    
    cd "${TARGET_PATCH_DIR}"

    # Handle clean down/decompression lifecycle
    if [ -f "${RT_PATCH}" ]; then
        echo -e "${YELLOW}[WARNING] Decompressed patch ${RT_PATCH} already exists.${NC}"
        if [ "${FORCE_OVERWRITE}" = "true" ] || ask_user "Do you want to re-download and overwrite it?" "N"; then
            rm -f "${RT_PATCH}" "${RT_PATCH_XZ}" 2>/dev/null
            echo -e "[DOWNLOAD] Pulling: ${PATCH_URL}"
            wget --show-progress -O "${RT_PATCH_XZ}" "${PATCH_URL}"
            echo -e "[VERBOSE] Decompressing patch file..."
            unxz -v -f "${RT_PATCH_XZ}"
        else
            echo -e "${GREEN}[SKIP] Keeping existing patch.${NC}"
        fi
    else
        rm -f "${RT_PATCH_XZ}" 2>/dev/null
        echo -e "[DOWNLOAD] Pulling: ${PATCH_URL}"
        wget --show-progress -O "${RT_PATCH_XZ}" "${PATCH_URL}"
        echo -e "[VERBOSE] Decompressing patch file..."
        unxz -v -f "${RT_PATCH_XZ}"
    fi
fi

# ==============================================================================
# STEP 4: Apply PREEMPT-RT Patch
# ==============================================================================
if [ "${INTERACTIVE_MODE}" = "true" ]; then
    if ask_user "Step 4: Do you want to apply the PREEMPT-RT Patch to the tree?" "Y"; then
        RUN_PATCH=true
    fi
fi

if [ "${RUN_PATCH}" = "true" ]; then
    echo -e "\n${BLUE}----------------------------------------------------------------------${NC}"
    echo -e " STEP 4: Patching Kernel Codebase"
    echo -e "${BLUE}----------------------------------------------------------------------${NC}"
    
    TARGET_PATCH_DIR="${BUILD_DIR}/linux-${KERNEL_VER}"
    if [ ! -d "${TARGET_PATCH_DIR}" ]; then
        echo -e "${RED}[ERROR] Kernel codebase directory ${TARGET_PATCH_DIR} does not exist. Cannot apply patch.${NC}"
        exit 1
    fi
    
    cd "${TARGET_PATCH_DIR}"
    
    if [ ! -f "${RT_PATCH}" ]; then
        echo -e "${RED}[ERROR] Decompressed patch file ${RT_PATCH} is missing inside $(pwd). Run Step 3 first.${NC}"
        exit 1
    fi

    echo -e "[VERBOSE] Running patch dry-run test..."
    if patch -p1 --dry-run < "${RT_PATCH}" >/dev/null 2>&1; then
        echo -e "${GREEN}[SUCCESS] Dry run passed cleanly. Applying patch...${NC}"
        patch -p1 < "${RT_PATCH}"
        echo -e "${GREEN}[SUCCESS] PREEMPT-RT patch successfully applied to kernel!${NC}"
    else
        echo -e "${YELLOW}[WARNING] Patch dry run failed. Checking if already applied...${NC}"
        if patch -p1 -R --dry-run --silent < "${RT_PATCH}" >/dev/null 2>&1; then
            echo -e "${YELLOW}[SKIP] Patch has already been applied previously. Nothing to do.${NC}"
        else
            echo -e "${RED}[ERROR] Patch application failed. Codebase may be modified or mismatched.${NC}"
            exit 1
        fi
    fi
fi

# Restore files ownership to user account if executed via sudo
if [ "${REAL_USER}" != "root" ]; then
    chown -R "${REAL_USER}:${REAL_USER}" "${BUILD_DIR}"
fi

echo -e "\n${BLUE}======================================================================${NC}"
echo -e "${GREEN} PIPELINE SELECTION EXECUTED SUCCESSFULLY!${NC}"
echo -e " Files reside strictly in: ${BUILD_DIR}"
echo -e "${BLUE}======================================================================${NC}"
