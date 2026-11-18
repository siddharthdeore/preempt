#!/usr/bin/env bash
# ==============================================================================
# Script: 03_compile_kernel.sh
# Description: Automate kernel config adjusting, stripping keys, and compiling.
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
KERNEL_DIR="${BUILD_DIR}/linux-${KERNEL_VER}"

# Initialize operation flags (defaulting to false unless set by args)
RUN_COPY_CONFIG=false
RUN_STRIP_KEYS=false
RUN_TUNE_RT=false
RUN_COMPILATION=false
INTERACTIVE_MODE=true

# ==============================================================================
# Helper Functions
# ==============================================================================

show_usage() {
    echo -e "Usage: $0 [options]"
    echo -e "Options:"
    echo -e "  --all              Execute all configuration and compilation steps sequentially."
    echo -e "  --copy-config      Execute only the step to copy and prepare system boot config."
    echo -e "  --strip-keys       Execute only the step to strip signing keys and debug symbols."
    echo -e "  --tune-rt          Execute only the step to enable PREEMPT_RT preemption."
    echo -e "  --compile          Execute only the final compilation step to build Debian packages."
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

# ==============================================================================
# Argument Parsing
# ==============================================================================

if [ $# -gt 0 ]; then
    INTERACTIVE_MODE=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all)
                RUN_COPY_CONFIG=true
                RUN_STRIP_KEYS=true
                RUN_TUNE_RT=true
                RUN_COMPILATION=true
                shift
                ;;
            --copy-config)
                RUN_COPY_CONFIG=true
                shift
                ;;
            --strip-keys)
                RUN_STRIP_KEYS=true
                shift
                ;;
            --tune-rt)
                RUN_TUNE_RT=true
                shift
                ;;
            --compile)
                RUN_COMPILATION=true
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
echo -e "${BLUE} STARTING RT-KERNEL CONFIGURATION AND COMPILATION WORKFLOW${NC}"
echo -e "${BLUE}======================================================================${NC}"
echo -e " Logged in user:      ${USER}"
echo -e " Target developer:    ${REAL_USER}"
echo -e " Target Codebase:     ${KERNEL_DIR}"
echo -e " CPU Build Cores:     $(nproc)"
echo -e " Interactive Mode:    ${INTERACTIVE_MODE}"
echo -e "${BLUE}======================================================================${NC}"

if [ ! -d "${KERNEL_DIR}" ]; then
    echo -e "${RED}[ERROR] Kernel codebase directory ${KERNEL_DIR} not found. Run Step 2 (extraction & patching) first!${NC}"
    exit 1
fi

cd "${KERNEL_DIR}"

# ==============================================================================
# STEP 1: Copy existing configuration template
# ==============================================================================
if [ "${INTERACTIVE_MODE}" = "true" ]; then
    if ask_user "Step 1: Copy existing system kernel configuration template?" "Y"; then
        RUN_COPY_CONFIG=true
    fi
fi

if [ "${RUN_COPY_CONFIG}" = "true" ]; then
    echo -e "\n${BLUE}----------------------------------------------------------------------${NC}"
    echo -e " STEP 1: Copying and Preparing Base Configuration Template"
    echo -e "${BLUE}----------------------------------------------------------------------${NC}"
    
    ACTIVE_CONFIG="/boot/config-$(uname -r)"
    if [ -f "${ACTIVE_CONFIG}" ]; then
        cp "${ACTIVE_CONFIG}" .config
        echo -e "${GREEN}[SUCCESS] Configuration copied from ${ACTIVE_CONFIG}.${NC}"
    else
        echo -e "${YELLOW}[WARNING] Active system config not found at ${ACTIVE_CONFIG}. Initializing default config...${NC}"
        make defconfig
    fi
    
    echo -e "[VERBOSE] Merging configurations against new kernel template..."
    make olddefconfig
fi

# ==============================================================================
# STEP 2: Strip trusted certificates & debug symbols
# ==============================================================================
if [ "${INTERACTIVE_MODE}" = "true" ]; then
    if ask_user "Step 2: Strip system signing keys and disable debug symbols (Highly Recommended to prevent build crash & speed up compilation)?" "Y"; then
        RUN_STRIP_KEYS=true
    fi
fi

if [ "${RUN_STRIP_KEYS}" = "true" ]; then
    echo -e "\n${BLUE}----------------------------------------------------------------------${NC}"
    echo -e " STEP 2: Stripping Security Keys and Debug Configurations"
    echo -e "${BLUE}----------------------------------------------------------------------${NC}"
    
    if [ ! -f ".config" ]; then
        echo -e "${RED}[ERROR] No .config file found. You must run Step 1 before altering properties.${NC}"
        exit 1
    fi

    echo -e "[VERBOSE] Disabling SYSTEM_TRUSTED_KEYS and SYSTEM_REVOCATION_KEYS..."
    scripts/config --disable SYSTEM_TRUSTED_KEYS
    scripts/config --disable SYSTEM_REVOCATION_KEYS
    scripts/config --set-str SYSTEM_TRUSTED_KEYS ""
    scripts/config --set-str SYSTEM_REVOCATION_KEYS ""

    echo -e "[VERBOSE] Disabling DEBUG_INFO profiles to optimize storage and speed up build..."
    scripts/config --disable DEBUG_INFO
    scripts/config --disable DEBUG_INFO_DWARF_TOOLCHAIN_AS_ROOT
    scripts/config --disable DEBUG_INFO_DWARF4
    scripts/config --disable DEBUG_INFO_DWARF5
    
    echo -e "${GREEN}[SUCCESS] Key security modules stripped, and debugging settings minimized.${NC}"
fi

# ==============================================================================
# STEP 3: Enable PREEMPT_RT real-time preemption model
# ==============================================================================
if [ "${INTERACTIVE_MODE}" = "true" ]; then
    if ask_user "Step 3: Enable PREEMPT_RT scheduler & configure custom local kernel version name?" "Y"; then
        RUN_TUNE_RT=true
    fi
fi

if [ "${RUN_TUNE_RT}" = "true" ]; then
    echo -e "\n${BLUE}----------------------------------------------------------------------${NC}"
    echo -e " STEP 3: Enabling PREEMPT_RT Preemption Scheduling"
    echo -e "${BLUE}----------------------------------------------------------------------${NC}"
    
    if [ ! -f ".config" ]; then
        echo -e "${RED}[ERROR] No .config file found. You must run Step 1 first.${NC}"
        exit 1
    fi

    echo -e "[VERBOSE] Toggling kernel scheduler to Real-Time (Fully Preemptible)..."
    scripts/config --enable PREEMPT_RT
    
    echo -e "[VERBOSE] Setting custom kernel tag suffix to '-rt-patched'..."
    scripts/config --set-str LOCALVERSION "-rt-patched"
    
    echo -e "[VERBOSE] Re-applying configuration consistency checks..."
    make olddefconfig
    
    echo -e "${GREEN}[SUCCESS] Configuration successfully prepared for PREEMPT_RT!${NC}"
fi

# ==============================================================================
# STEP 4: Compile Kernel and Generate debian packages
# ==============================================================================
if [ "${INTERACTIVE_MODE}" = "true" ]; then
    if ask_user "Step 4: Start kernel compilation (Using $(nproc) hardware threads)?" "Y"; then
        RUN_COMPILATION=true
    fi
fi

if [ "${RUN_COMPILATION}" = "true" ]; then
    echo -e "\n${BLUE}----------------------------------------------------------------------${NC}"
    echo -e " STEP 4: Compiling Kernel Codebase into Debian Packages (.deb)"
    echo -e "${BLUE}----------------------------------------------------------------------${NC}"
    
    if [ ! -f ".config" ]; then
        echo -e "${RED}[ERROR] Configuration file .config not found. Run previous configuration steps first.${NC}"
        exit 1
    fi

    CORES=$(nproc)
    echo -e "${YELLOW}Starting compile with ${CORES} CPU cores...${NC}"
    echo -e "${YELLOW}Compilation takes roughly 15 to 45 minutes depending on processor speed.${NC}"
    
    # Build kernel package
    make -j"${CORES}" deb-pkg
fi

# Restore files ownership to user account if executed via sudo
if [ "${REAL_USER}" != "root" ]; then
    chown -R "${REAL_USER}:${REAL_USER}" "${BUILD_DIR}"
fi

echo -e "\n${BLUE}======================================================================${NC}"
echo -e "${GREEN} PIPELINE CONFIGURATION EXECUTED SUCCESSFULLY!${NC}"
echo -e " Destination folder: ${BUILD_DIR}"
if [ "${RUN_COMPILATION}" = "true" ]; then
    echo -e " To install the generated real-time kernel, run:"
    echo -e "   ${YELLOW}sudo dpkg -i ${BUILD_DIR}/*.deb${NC}"
fi
echo -e "${BLUE}======================================================================${NC}"
