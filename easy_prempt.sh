#!/bin/sh
# Script prepares system to build system, downloads most suitable RT patch and kernel source,
# and patches the kernel.
# author : siddharth deore

NC='\033[0m' # No Color

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

# Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White

# Underline
UBlack='\033[4;30m'       # Black
URed='\033[4;31m'         # Red
UGreen='\033[4;32m'       # Green
UYellow='\033[4;33m'      # Yellow
UBlue='\033[4;34m'        # Blue
UPurple='\033[4;35m'      # Purple
UCyan='\033[4;36m'        # Cyan
UWhite='\033[4;37m'       # White

# Background
On_Black='\033[40m'       # Black
On_Red='\033[41m'         # Red
On_Green='\033[42m'       # Green
On_Yellow='\033[43m'      # Yellow
On_Blue='\033[44m'        # Blue
On_Purple='\033[45m'      # Purple
On_Cyan='\033[46m'        # Cyan
On_White='\033[47m'       # White

# High Intensity
IBlack='\033[0;90m'       # Black
IRed='\033[0;91m'         # Red
IGreen='\033[0;92m'       # Green
IYellow='\033[0;93m'      # Yellow
IBlue='\033[0;94m'        # Blue
IPurple='\033[0;95m'      # Purple
ICyan='\033[0;96m'        # Cyan
IWhite='\033[0;97m'       # White

# Bold High Intensity
BIBlack='\033[1;90m'      # Black
BIRed='\033[1;91m'        # Red
BIGreen='\033[1;92m'      # Green
BIYellow='\033[1;93m'     # Yellow
BIBlue='\033[1;94m'       # Blue
BIPurple='\033[1;95m'     # Purple
BICyan='\033[1;96m'       # Cyan
BIWhite='\033[1;97m'      # White

# High Intensity backgrounds
On_IBlack='\033[0;100m'   # Black
On_IRed='\033[0;101m'     # Red
On_IGreen='\033[0;102m'   # Green
On_IYellow='\033[0;103m'  # Yellow
On_IBlue='\033[0;104m'    # Blue
On_IPurple='\033[0;105m'  # Purple
On_ICyan='\033[0;106m'    # Cyan
On_IWhite='\033[0;107m'   # White

# kernel version
VER=`uname -r`
MAJ=`uname -r | cut -d '.' -f1`
MIN=`uname -r | cut -d '.' -f2`
REV=`uname -r | cut -d '.' -f3`

# Install Prerequisites
# download kernel requirements
# sudo apt-get install -y lftp 
# menuconfig GUI requirements
# building and compiling requirements

echo ${info} ${Red}"Installing Prerequisites"${NC}

sudo apt-get install build-essential
sudo apt-get install -y fakeroot libnuma-dev
sudo apt install -y kernel-package libncurses5 libncurses5-dev libncurses-dev qtbase5-dev-tools flex
sudo apt install -y bison openssl libssl-dev dkms libelf-dev libudev-dev libpci-dev libiberty-dev autoconf
sudo apt install -y dwarves
sudo apt install -y zstd

sleep 0.1

# kernel source code path
if [ "$MAJ" -gt "2" ]; then
    KER_PATH="https://cdn.kernel.org/pub/linux/kernel/v"$MAJ.x/
else
    KER_PATH="https://cdn.kernel.org/pub/linux/kernel/v"$MAJ.$MIN/
fi
# RT patch code path
RTK_PATH="https://cdn.kernel.org/pub/linux/kernel/projects/rt/"$MAJ.$MIN

info="${Green}[  INFO  ]${NC}"
echo ${info} "Searching for kernel patch suitable for " ${BRed}$VER${NC}"\n"

PATCH_COMPRESSED_FILE_NAME=`lftp -e "cls -1 *.patch.gz; exit" ${RTK_PATH}`
echo "\n"${info} Found patch ${Green}$PATCH_COMPRESSED_FILE_NAME${NC}
PATCH_URL=${RTK_PATH}/${PATCH_COMPRESSED_FILE_NAME}
echo ${info} Downloading patch ${UYellow}${PATCH_URL}${NC}
#################################################################
# downlad patch
#wget ${PATCH_URL}
# extract patch
#gunzip ${PATCH_COMPRESSED_FILE_NAME}
PATCH_NAME=`echo ${PATCH_COMPRESSED_FILE_NAME%.gz}`
#################################################################

echo ${info} "Searching for kernel source suitable for " ${BRed}$VER${NC}"\n"
# get list of available kernel sources
KERN_FILE_NAME=`lftp -e "set ftp:ssl-allow no; cls -1 linux-${MAJ}.${MIN}.*.tar.gz; exit" ${KER_PATH}` 
KERN_FILE_NAME=`echo ${KERN_FILE_NAME} | cut -d ' ' -f1`
echo "\n"${info} Found kernel source ${Green} ${KERN_FILE_NAME} ${NC}
SOURCE_URL=${KER_PATH}${KERN_FILE_NAME}
echo ${info} Downloading kernel ${UYellow}${SOURCE_URL}${NC}
#################################################################
# download kernel source
#wget ${SOURCE_URL}
# extract source
#tar -xzf ${KERN_FILE_NAME}
#################################################################
KERN_DIR_NAME=`echo ${KERN_FILE_NAME%.tar.gz}`
# change directory
cd ${KERN_DIR_NAME}
#################################################################
# patch kernel
#patch -p1 < ../${PATCH_NAME}
#################################################################
# copy current configration settings
#cp /boot/config-$(uname -r) .config
#yes '' | make oldconfig
#make menuconfig

scripts/config --set-str CONFIG_SYSTEM_REVOCATION_KEYS ""
scripts/config --set-str CONFIG_SYSTEM_TRUSTED_KEYS ""

echo "\n"${info} ${BICyan}"now you can make kernel\n"${NC}
# scripts/config --set-val CONFIG_HAVE_PREEMPT_LAZY y
# scripts/config --set-val CONFIG_PREEMPT_LAZY y
# scripts/config -d CONFIG_PREEMPT_VOLUNTARY

# sudo make modules_install -j$(nproc)
# sudo make install -j$(nproc)
# sudo update-grub
# sudo reboot
