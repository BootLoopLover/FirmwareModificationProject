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
echo -e "${BLUE}Firmware Modifications Project${NC}"
echo -e "${BLUE}Create By Pakalolo${NC}"
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

# === Tanyakan apakah ingin install dependencies ===
read -p "Do you want to update and install build dependencies? (y/n): " update_deps
update_deps=${update_deps,,}  # Lowercase input

if [[ "$update_deps" == "y" || "$update_deps" == "yes" ]]; then
    echo -e "${BLUE}Installing required build dependencies...${NC}"
    sudo apt update -y
    sudo apt install -y $deps
else
    echo -e "${GREEN}Skipping dependency installation as requested.${NC}"
fi

# === Clone Source Repo ===
[ -d "$distro" ] && echo -e "${BLUE}Removing existing '${distro}'...${NC}" && rm -rf "$distro"
echo -e "${BLUE}Cloning repository from GitHub...${NC}"
git clone "$repo" "$distro"

cd "$distro"

# === Update Feeds ===
echo -e "${BLUE}Initializing and installing feeds...${NC}"
./scripts/feeds update -a
./scripts/feeds install -a

# === Tag dan Branch ===
echo -e "${BLUE}Available tags (recommended base versions):${NC}"
git tag | sort -V
read -p "Enter tag to base your build on (leave empty to use default branch): " TARGET_TAG
if [[ -n "$TARGET_TAG" ]]; then
    git fetch --tags
    git checkout "$TARGET_TAG"
fi

branch_name="build-$(date +%Y%m%d-%H%M)"
echo -e "${BLUE}Creating and switching to Git branch: ${branch_name}${NC}"
git switch -c "$branch_name"

# === Pilihan Feeds Tambahan ===
echo "Pilih opsi feeds yang ingin ditambahkan:"
echo "  1) no feeds"
echo "  2) add qmodem feeds"
echo "  3) add pakalolopackage feeds"
echo "  4) add php7 feeds"
echo "  5) add all feeds"
read -p "Enter your choice [1/2/3/4/5]: " choice

case "$choice" in
    1)
        echo "Tidak ada feed yang ditambahkan."
        ;;
    2)
        echo 'src-git qmodem https://github.com/BootLoopLover/qmodem.git' >> feeds.conf.default
        ;;
    3)
        echo 'src-git pakalolopackage https://github.com/BootLoopLover/pakalolo-package.git' >> feeds.conf.default
        ;;
    4)
        echo 'src-git php7 https://github.com/BootLoopLover/openwrt-php7-package.git' >> feeds.conf.default
        ;;
    5)
        echo 'src-git qmodem https://github.com/BootLoopLover/qmodem.git' >> feeds.conf.default
        echo 'src-git pakalolopackage https://github.com/BootLoopLover/pakalolo-package.git' >> feeds.conf.default
        echo 'src-git php7 https://github.com/BootLoopLover/openwrt-php7-package.git' >> feeds.conf.default
        ;;
    *)
        echo "Pilihan tidak valid. Tidak ada feed yang ditambahkan."
        ;;
esac

read -p "Tekan [Enter] untuk melanjutkan setelah mengubah feeds jika perlu..." temp

# === Pilihan Folder Preset ===
echo -e "${BLUE}Select which preset to use:${NC}"
echo "Note : Autobuild Script Preset For Compiler Only...Please Choose None"
echo "1) None"
echo "2) preset-openwrt"
echo "3) preset-immortalwrt"
echo "4) preset-nss"
echo "5) All"
read -p "Enter your choice [1/2/3/4/5]: " preset_choice

skip_menuconfig=false

function clone_and_copy_preset() {
    local repo_url=$1
    local folder_name=$2
    echo -e "${BLUE}Cloning ${folder_name} from GitHub...${NC}"
    git clone "$repo_url" "../$folder_name" || {
        echo -e "${RED}Failed to clone ${folder_name}.${NC}"; return
    }
    if [ -d "../$folder_name/files" ]; then
        mkdir -p files
        cp -r "../$folder_name/files/"* files/
    fi
    if [ -f "../$folder_name/config-nss" ]; then
        cp "../$folder_name/config-nss" .config
        skip_menuconfig=true
    fi
}

[[ "$preset_choice" == "2" || "$preset_choice" == "5" ]] && clone_and_copy_preset "https://github.com/BootLoopLover/preset-openwrt.git" "preset-openwrt"
[[ "$preset_choice" == "3" || "$preset_choice" == "5" ]] && clone_and_copy_preset "https://github.com/BootLoopLover/preset-immortalwrt.git" "preset-immortalwrt"
[[ "$preset_choice" == "4" || "$preset_choice" == "5" ]] && clone_and_copy_preset "https://github.com/BootLoopLover/preset-nss.git" "preset-nss"

# === Update Feeds Ulang ===
echo -e "${BLUE}Updating feeds again...${NC}"
./scripts/feeds update -a
./scripts/feeds install -a

# === Menuconfig ===
if [ "$skip_menuconfig" = false ]; then
    echo -e "${BLUE}Launching configuration menu...${NC}"
    make menuconfig
else
    echo -e "${BLUE}Skipping menuconfig as .config has been preseeded.${NC}"
fi

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

