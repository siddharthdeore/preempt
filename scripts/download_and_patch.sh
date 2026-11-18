#!/usr/bin/env bash
# ==============================================================================
# Script: 02_download_and_patch.sh
# Description: Download Kernel 7.2 source code and apply PREEMPT-RT patch.
#              Enforces workspace in home directory with verbose debugging.
# ==============================================================================

set -uo pipefail

# 1. Enforce target directory irrespective of where the script is run from
TARGET_USER_HOME=$(eval echo "~${USER}")
BUILD_DIR="${TARGET_USER_HOME}/rt-kernel"
KERNEL_VER="7.2"
KERNEL_TAR="linux-${KERNEL_VER}.tar.xz"
KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v7.x/${KERNEL_TAR}"

RT_PATCH="patch-7.2-rt5.patch"
RT_PATCH_XZ="${RT_PATCH}.xz"
PATCH_URL="https://cdn.kernel.org/pub/linux/projects/rt/7.2/${RT_PATCH_XZ}"

echo "======================================================================"
echo "🚀 STARTING RT-KERNEL DOWNLOAD & PATCH WORKFLOW"
echo "======================================================================"
echo "📍 Current User:     ${USER}"
echo "📍 Target Directory: ${BUILD_DIR}"
echo "======================================================================"

# Ensure target directory exists and enter it
echo "⚙️ [VERBOSE] Creating workspace directory: ${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}" || { echo "❌ [ERROR] Failed to navigate to ${BUILD_DIR}"; exit 1; }

# Confirm current directory matches target
echo "⚙️ [VERBOSE] Working directory successfully set to: $(pwd)"


# ==============================================================================
# 2. Kernel Source Download & Extraction
# ==============================================================================
echo "----------------------------------------------------------------------"
echo "📥 STEP 1: Handling Kernel Source (${KERNEL_TAR})"
echo "----------------------------------------------------------------------"

if [ ! -f "${BUILD_DIR}/${KERNEL_TAR}" ]; then
    echo "⚙️ [VERBOSE] ${KERNEL_TAR} not found in workspace. Pulling from server..."
    echo "🌍 [DOWNLOAD] ${KERNEL_URL}"
    # Using verbose download progress instead of quiet mode
    wget --show-progress -O "${BUILD_DIR}/${KERNEL_TAR}" "${KERNEL_URL}"
    if [ $? -eq 0 ]; then
        echo "✅ [SUCCESS] Kernel source downloaded successfully."
    else
        echo "❌ [ERROR] Failed to download Kernel source. Check connection/DNS."
        exit 1
    fi
else
    echo "ℹ️ [SKIP] ${KERNEL_TAR} already exists in ${BUILD_DIR}. Skipping download."
fi

# Extraction Phase
if [ ! -d "${BUILD_DIR}/linux-${KERNEL_VER}" ]; then
    echo "⚙️ [VERBOSE] Extracting kernel sources to ${BUILD_DIR}/linux-${KERNEL_VER}..."
    tar -xvf "${BUILD_DIR}/${KERNEL_TAR}" -C "${BUILD_DIR}/"
    if [ $? -eq 0 ]; then
        echo "✅ [SUCCESS] Kernel source successfully extracted."
    else
        echo "❌ [ERROR] Extraction failed."
        exit 1
    fi
else
    echo "ℹ️ [SKIP] Directory linux-${KERNEL_VER} already exists. Skipping extraction."
fi


# ==============================================================================
# 3. RT Patch Download & Decompression
# ==============================================================================
echo "----------------------------------------------------------------------"
echo "📥 STEP 2: Handling PREEMPT-RT Patch"
echo "----------------------------------------------------------------------"

# Navigate into the kernel source tree for patching
cd "${BUILD_DIR}/linux-${KERNEL_VER}" || { echo "❌ [ERROR] Failed to enter source directory"; exit 1; }
echo "⚙️ [VERBOSE] Entered directory: $(pwd)"

if [ ! -f "${RT_PATCH}" ]; then
    echo "⚙️ [VERBOSE] ${RT_PATCH} not found. Pulling zipped patch..."
    echo "🌍 [DOWNLOAD] ${PATCH_URL}"
    wget --show-progress -O "${RT_PATCH_XZ}" "${PATCH_URL}"
    if [ $? -eq 0 ]; then
        echo "✅ [SUCCESS] Zipped patch downloaded successfully."
    else
        echo "❌ [ERROR] Failed to download patch. Check your internet connection."
        exit 1
    fi
    
    echo "⚙️ [VERBOSE] Decompressing ${RT_PATCH_XZ}..."
    unxz -v -f "${RT_PATCH_XZ}"
    if [ $? -eq 0 ]; then
        echo "✅ [SUCCESS] Patch file decompressed successfully to $(pwd)/${RT_PATCH}"
    else
        echo "❌ [ERROR] Decompression failed."
        exit 1
    fi
else
    echo "ℹ️ [SKIP] Decompressed ${RT_PATCH} already exists. Skipping download."
fi


# ==============================================================================
# 4. Dry-run and Apply PREEMPT-RT Patch
# ==============================================================================
echo "----------------------------------------------------------------------"
echo "🔧 STEP 3: Patching Process"
echo "----------------------------------------------------------------------"

echo "⚙️ [VERBOSE] Executing dry run of patch command to prevent tree corruption..."
if patch -p1 --dry-run < "${RT_PATCH}"; then
    echo "✅ [SUCCESS] Patch dry run passed cleanly. Applying patch for real..."
    patch -p1 < "${RT_PATCH}"
    echo "🎉 [SUCCESS] PREEMPT-RT patch successfully applied to kernel!"
else
    echo "⚠️ [WARNING] Dry run failed. Checking if kernel is already patched..."
    # Reverse patch check to confirm if the patch is already applied
    if patch -p1 -R --dry-run --silent < "${RT_PATCH}" >/dev/null 2>&1; then
        echo "ℹ️ [SKIP] Patch has already been applied previously. Nothing to do."
    else
        echo "❌ [ERROR] Patch dry run failed completely. Source tree is corrupt/mismatched."
        exit 1
    fi
fi

echo "======================================================================"
echo "🏁 WORKFLOW COMPLETE!"
echo "📍 Cleaned files ready in: ${BUILD_DIR}/linux-${KERNEL_VER}"
echo "======================================================================"
