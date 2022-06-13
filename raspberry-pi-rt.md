# Raspberry PI 4B preempt-rt kernel cross compilation

# Step 1: Essenttial tools to build kernel.
Install essential utilities and build tools
```sh
sudo apt-get install -y build-essential libgmp-dev libmpfr-dev libmpc-dev
sudo apt-get install -y libisl-dev libncurses5-dev bc git-core bison flex
sudo apt-get install -y libncurses-dev libssl-dev
```

# Step 2: Install Cross Compiler
Download and install cross compiler utilities for aarch-64
```sh
# sudo apt install gcc make gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu
# or build from source
cd ~/Downloads
wget https://ftp.gnu.org/gnu/binutils/binutils-2.35.tar.bz2
tar xf binutils-2.35.tar.bz2
cd binutils-2.35/
./configure --prefix=/opt/aarch64 --target=aarch64-linux-gnu --disable-nls

# make and install binutils
make -j$(nproc)
sudo make install

# Export path
export PATH=$PATH:/opt/aarch64/bin/

# Build and install gcc from source
cd ..
# download and gcc source
wget https://ftp.gnu.org/gnu/gcc/gcc-8.4.0/gcc-8.4.0.tar.xz

# unpack archive
tar xf gcc-8.4.0.tar.xz
cd gcc-8.4.0/
./contrib/download_prerequisites
./configure --prefix=/opt/aarch64 --target=aarch64-linux-gnu --with-newlib --without-headers \
 --disable-nls --disable-shared --disable-threads --disable-libssp --disable-decimal-float \
 --disable-libquadmath --disable-libvtv --disable-libgomp --disable-libatomic \
 --enable-languages=c --disable-multilib

# Make and install gcc compiler
make all-gcc -j$(nproc)
sudo make install-gcc

# Check if compiler works
/opt/aarch64/bin/aarch64-linux-gnu-gcc -v
# or aarch64-linux-gnu-gcc if installed with apt-get
```

# Step 3: Patching Kernel and Configure 
```sh
mkdir ~/rpi-kernel
cd ~/rpi-kernel 

# Downlad stable Raspberry PI kernel source
git clone https://github.com/raspberrypi/linux.git -b rpi-5.15.y
# Download rt patch
wget https://mirrors.edge.kernel.org/pub/linux/kernel/projects/rt/5.15/patch-5.15.44-rt46.patch.gz

mkdir kernel-build

cd linux

# unpack the patch.
gzip -cd ../patch-5.15.44-rt46.patch.gz | patch -p1 --verbose

# configuration for Raspberry PI 4B
make O=../kernel-build/ ARCH=arm64 CROSS_COMPILE=/opt/aarch64/bin/aarch64-linux-gnu- bcm2711_defconfig

# enter the menuconfig
make O=../kernel-build/ ARCH=arm64 CROSS_COMPILE=/opt/aarch64/bin/aarch64-linux-gnu- menuconfig
```

# Step 4: Building RT Kernel

```sh
make -j$(nproc) O=../kernel-build/ ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-

# pack our Kernel 
export INSTALL_MOD_PATH=~/rpi-kernel/rt-kernel
export INSTALL_DTBS_PATH=~/rpi-kernel/rt-kernel
make O=../kernel-build/ ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- modules_install dtbs_install
cp ../kernel-build/arch/arm64/boot/Image ../rt-kernel/boot/kernel8.img
cd $INSTALL_MOD_PATH
tar czf ../rt-kernel.tgz *
cd ..

```
# Step 5: Installing New Kernel
```sh
# secure copy kernel archive to raspberi pi

scp rt-kernel.tgz pi@<ipaddress>:/tmp

# login pi through ssh
ssh pi@<ipaddress>
#  copy our files
cd /tmp
tar xzf rt-kernel.tgz
cd boot
sudo cp -rd * /boot/
cd ../lib
sudo cp -dr * /lib/
cd ../overlays
sudo cp -dr * /boot/overlays
cd ../broadcom
sudo cp -dr bcm* /boot/
# add following line to `/boot/config.txt`.
# kernel=kernel8.img

reboot

uname -a
```
# Step 6: Isolate CPUs from the kernel scheduler.
Remove the given CPUs, as indicated by the cpu number values, from the general kernel SMP balance and scheduler algorithms. The CPU affinity syscalls are the sole mechanism to transfer a process onto or off of a "isolated" CPU. To do so add following line to  `/boot/cmdline.txt`
``` sh
isolcpus=3      # isolate the CPU nr 3
# or
isolcpus=1-3  # isolate the CPUs nr 1, 2 & 3
```
establish the perticular interrupt's affinity towards a specific CPU type  e.g.:
```sh
sudo echo 3 > /proc/irq/62/smp_affinity
sudo echo 3 > /proc/irq/62/smp_affinity_list
```
Examine which interruptions are being scheduled and which CPU is responding to them.
```sh
cat /proc/interrupts
```