#!/bin/bash

# === Warna Terminal ===
BLUE='\033[1;34m'
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m'

# === Cek path skrip untuk spasi ===
current_path="$(pwd)"
if [[ "$current_path" == *" "* ]]; then
    echo -e "${RED}ERROR: Folder path contains spaces. Please move this script to a directory without spaces.${NC}"
    echo -e "${RED}Current path: '${current_path}'${NC}"
    exit 1
fi

# === Variabel ===
preset_folder="preset-openwrt"
script_file="$(basename "$0")"

# === Tampilan Awal ===
clear
echo -e "${BLUE}UNIVERSAL-WRT${NC}"
echo -e "${BLUE}Select the firmware distribution you want to build:${NC}"
echo "1) OpenWrt"
echo "2) OpenWrt-ipq"
echo "3) ImmortalWrt"
read -p "Enter your choice [1/2/3]: " choice

# === Pilihan Distro ===
if [[ "$choice" == "1" ]]; then
    distro="openwrt"
    repo="https://github.com/openwrt/openwrt.git"
    deps="build-essential clang flex bison g++ gawk gcc-multilib g++-multilib gettext \
    git libncurses5-dev libssl-dev python3-setuptools rsync swig unzip zlib1g-dev file wget"
elif [[ "$choice" == "2" ]]; then
    distro="openwrt-ipq"
    repo="https://github.com/qosmio/openwrt-ipq.git"
    deps="build-essential clang flex bison g++ gawk gcc-multilib g++-multilib gettext \
    git libncurses5-dev libssl-dev python3-setuptools rsync swig unzip zlib1g-dev file wget"
elif [[ "$choice" == "3" ]]; then
    distro="immortalwrt"
    repo="https://github.com/immortalwrt/immortalwrt.git"
    deps="ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential \
    bzip2 ccache clang cmake cpio curl device-tree-compiler ecj fastjar flex gawk gettext \
    gcc-multilib g++-multilib git gnutls-dev gperf haveged help2man intltool lib32gcc-s1 \
    libc6-dev-i386 libelf-dev libglib2.0-dev libgmp3-dev libltdl-dev libmpc-dev libmpfr-dev \
    libncurses-dev libpython3-dev libreadline-dev libssl-dev libtool libyaml-dev libz-dev \
    lld llvm lrzsz mkisofs msmtp nano ninja-build p7zip p7zip-full patch pkgconf python3 \
    python3-pip python3-ply python3-docutils python3-pyelftools qemu-utils re2c rsync \
    scons squashfs-tools subversion swig texinfo uglifyjs upx-ucl unzip vim wget xmlto \
    xxd zlib1g-dev zstd"
else
    echo -e "${RED}Invalid choice. Exiting.${NC}"
    exit 1
fi

# === Mode Clean ===
if [[ "$1" == "--clean" ]]; then
    echo -e "${BLUE}Cleaning up directories and script...${NC}"
    [ -d "$distro" ] && rm -rf "$distro"
    [ -f "$script_file" ] && rm -f "$script_file"
    exit 0
fi

# === Install Dependency ===
echo -e "${BLUE}Installing required build dependencies...${NC}"
sudo apt update -y
sudo apt install -y $deps

# === Clone Source Repo ===
[ -d "$distro" ] && echo -e "${BLUE}Removing existing '${distro}'...${NC}" && rm -rf "$distro"
echo -e "${BLUE}Cloning repository from GitHub...${NC}"
git clone $repo $distro

# === Masuk ke Folder Source ===
cd $distro

# === Pilihan Folder Preset ===
echo -e "${BLUE}Select which preset to use:${NC}"
echo "1) preset-openwrt"
echo "2) preset-immortalwrt"
echo "3) preset-nss"
echo "4) All"
read -p "Enter your choice [1/2/3/4]: " preset_choice

# === Clone dan Gabungkan Preset Sesuai Pilihan ===
mkdir -p files

if [[ "$preset_choice" == "1" || "$preset_choice" == "4" ]]; then
    if [ ! -d ../preset-openwrt ]; then
        echo -e "${BLUE}Cloning preset-openwrt from GitHub...${NC}"
        git clone https://github.com/BootLoopLover/preset-openwrt.git ../preset-openwrt || {
            echo -e "${RED}Failed to clone preset-openwrt.${NC}"; exit 1;
        }
    else
        echo -e "${GREEN}preset-openwrt already exists. Skipping clone.${NC}"
    fi
    cp -r ../preset-openwrt/* files/ 2>/dev/null
fi

if [[ "$preset_choice" == "2" || "$preset_choice" == "4" ]]; then
    if [ ! -d ../preset-immortalwrt ]; then
        echo -e "${BLUE}Cloning preset-immortalwrt from GitHub...${NC}"
        git clone https://github.com/BootLoopLover/preset-immortalwrt.git ../preset-immortalwrt || {
            echo -e "${RED}Failed to clone preset-immortalwrt.${NC}"; exit 1;
        }
    else
        echo -e "${GREEN}preset-immortalwrt already exists. Skipping clone.${NC}"
    fi
    cp -r ../preset-immortalwrt/* files/ 2>/dev/null
fi

if [[ "$preset_choice" == "3" || "$preset_choice" == "4" ]]; then
    if [ ! -d ../preset-nss ]; then
        echo -e "${BLUE}Cloning preset-nss from GitHub...${NC}"
        git clone https://github.com/BootLoopLover/preset-nss.git ../preset-nss || {
            echo -e "${RED}Failed to clone preset-nss.${NC}"; exit 1;
        }
    else
        echo -e "${GREEN}preset-nss already exists. Skipping clone.${NC}"
    fi
    cp -r ../preset-nss/* files/ 2>/dev/null
fi

# === Update Feeds ===
echo -e "${BLUE}Initializing and installing feeds...${NC}"
./scripts/feeds update -a
./scripts/feeds install -a

# === Tambahkan Feeds Tambahan ===
echo >> feeds.conf.default
echo 'src-git qmodem https://github.com/BootLoopLover/qmodem.git' >> feeds.conf.default
echo 'src-git pakalolopackage https://github.com/BootLoopLover/pakalolo-package.git' >> feeds.conf.default
read -p "Press [Enter] to continue after modifying feeds if needed..." temp

# === Update Feeds Ulang ===
./scripts/feeds update -a
./scripts/feeds install -a

# === Tampilkan Branch dan Tag ===
echo -e "${BLUE}Available branches:${NC}"
git branch -a
echo -e "${BLUE}Available tags:${NC}"
git tag | sort -V
read -p "Enter branch/tag to checkout: " TARGET_TAG
git checkout $TARGET_TAG

# === Config Khusus IPQ ===
if [[ "$choice" == "2" ]]; then
    echo -e "${BLUE}Applying preseeded .config for OpenWrt-IPQ...${NC}"
    cp nss-setup/config-nss.seed .config
fi

# === Buka Menuconfig ===
echo -e "${BLUE}Launching configuration menu...${NC}"
make menuconfig

# === Mulai Build ===
echo -e "${BLUE}Starting build process...${NC}"
start_time=$(date +%s)

if make -j$(nproc); then
    echo -e "${GREEN}Build completed successfully.${NC}"
else
    echo -e "${RED}Build failed. Retrying with verbose output...${NC}"
    make -j1 V=s
    echo -e "${RED}Build finished with errors.${NC}"
fi

# === Waktu Build ===
end_time=$(date +%s)
duration=$((end_time - start_time))
hours=$((duration / 3600))
minutes=$(((duration % 3600) / 60))
echo -e "${BLUE}Total build time: ${hours} hour(s) and ${minutes} minute(s).${NC}"

# === Hapus Skrip Sendiri ===
cd ..
echo -e "${BLUE}Cleaning up this script file '${script_file}'...${NC}"
rm -f "$script_file"
