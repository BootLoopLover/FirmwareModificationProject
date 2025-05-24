#!/bin/bash
#--------------------------------------------------------
#   🚧 Firmware Modification Project - Universal Builder 🚧
#   👨‍💻 Author: Pakalolo Waraso
#   🤝 Special Thanks: Awiks Telegram Group
#   🔗 GitHub: https://github.com/BootLoopLover
#--------------------------------------------------------

# === 🎨 Terminal Colors ===
BLUE='\033[1;34m'
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m'

# === ❗ Path Check for Spaces ===
current_path="$(pwd)"
if [[ "$current_path" == *" "* ]]; then
    echo -e "${RED}❌ ERROR: Folder path contains spaces. Move the script to a directory without spaces.${NC}"
    echo -e "${RED}📂 Current path: '${current_path}'${NC}"
    exit 1
fi

# === ⚙️ Variables ===
preset_folder="preset-openwrt"
script_file="$(basename "$0")"

# === 👋 Welcome Message ===
clear
echo "========== 🧰 Universal OpenWrt/ImmortalWrt/OpenWrt-IPQ Builder =========="
echo -e "${BLUE}🔧 Firmware Modifications Project${NC}"
echo -e "${BLUE}🌐 GitHub : https://github.com/BootLoopLover${NC}"
echo -e "${BLUE}💬 Telegram : t.me/PakaloloWaras0${NC}"
echo "====================================================================="
echo -e "${BLUE}📦 Select the firmware distribution to build:${NC}"
echo "1) 🐧 OpenWrt"
echo "2) 🚀 OpenWrt-IPQ"
echo "3) 🛡️ ImmortalWrt"
echo "====================================================================="
read -p "🔢 Enter your choice [1/2/3]: " choice

# === 🔄 Distribution Selection ===
case "$choice" in
    1)
        distro="openwrt"
        repo="https://github.com/openwrt/openwrt.git"
        deps="build-essential clang flex bison g++ gawk gcc-multilib g++-multilib gettext git libncurses5-dev libssl-dev python3-setuptools rsync swig unzip zlib1g-dev file wget"
        ;;
    2)
        distro="openwrt-ipq"
        repo="https://github.com/qosmio/openwrt-ipq.git"
        deps="build-essential clang flex bison g++ gawk gcc-multilib g++-multilib gettext git libncurses5-dev libssl-dev python3-setuptools rsync swig unzip zlib1g-dev file wget"
        ;;
    3)
        distro="immortalwrt"
        repo="https://github.com/immortalwrt/immortalwrt.git"
        deps="... (panjang, tidak diubah)"
        ;;
    *)
        echo -e "${RED}🚫 Invalid choice. Exiting.${NC}"
        exit 1
        ;;
esac

# === 🧹 Cleanup Mode ===
if [[ "$1" == "--clean" ]]; then
    echo -e "${BLUE}🧽 Cleaning up previous directories and script...${NC}"
    [ -d "$distro" ] && rm -rf "$distro"
    [ -f "$script_file" ] && rm -f "$script_file"
    exit 0
fi

# === 📦 Dependency Installation ===
read -p "📥 Do you want to install required dependencies? (y/n): " update_deps
update_deps=${update_deps,,}

if [[ "$update_deps" =~ ^(y|yes)$ ]]; then
    echo -e "${BLUE}🔧 Installing build dependencies...${NC}"
    sudo apt update -y
    sudo apt install -y $deps
else
    echo -e "${GREEN}⏩ Skipping dependency installation.${NC}"
fi

# === ⬇️ Clone Repository ===
[ -d "$distro" ] && echo -e "${BLUE}♻️ Removing existing directory: $distro${NC}" && rm -rf "$distro"
echo -e "${BLUE}🔄 Cloning source code...${NC}"
git clone "$repo" "$distro"
cd "$distro"

# === 🍴 Feed Update ===
echo -e "${BLUE}🔁 Updating and installing feeds...${NC}"
./scripts/feeds update -a
./scripts/feeds install -a

# === 🔀 Git Tag/Branch Selection ===
echo -e "${BLUE}🏷️ Available Git tags:${NC}"
git tag | sort -V
read -p "🔖 Enter tag to checkout (leave empty for default branch): " TARGET_TAG
[[ -n "$TARGET_TAG" ]] && git fetch --tags && git checkout "$TARGET_TAG"

branch_name="build-$(date +%Y%m%d-%H%M)"
echo -e "${BLUE}🌿 Creating new branch: $branch_name${NC}"
git switch -c "$branch_name"

# === 🍱 Additional Feeds ===
echo "========== 📦 Feeds Menu =========="
echo "1) ❌ None"
echo "2) 🧰 Add Custom Package Feed"
echo "3) 🐘 Add PHP7 Feed"
echo "4) 💯 Add All Feeds"
echo "=================================="
read -p "🔢 Select feed option [1-4]: " choice

case "$choice" in
    2) echo 'src-git custompackage https://github.com/BootLoopLover/custom-package.git' >> feeds.conf.default ;;
    3) echo 'src-git php7 https://github.com/BootLoopLover/openwrt-php7-package.git' >> feeds.conf.default ;;
    4)
        echo 'src-git custompackage https://github.com/BootLoopLover/custom-package.git' >> feeds.conf.default
        echo 'src-git php7 https://github.com/BootLoopLover/openwrt-php7-package.git' >> feeds.conf.default
        ;;
    *) echo "⚠️ No feeds added." ;;
esac

read -p "⏸️ Press [Enter] to continue after modifying feeds..." temp

# === 🗂️ Preset Configuration ===
echo "========== ⚙️ Preset Menu =========="
echo "1) ❌ None"
echo "2) 🧾 preset-openwrt"
echo "3) 🛡️ preset-immortalwrt"
echo "4) ⚡ preset-nss"
echo "5) 📦 All"
echo "=================================="
read -p "🔢 Select preset option [1-5]: " preset_choice

skip_menuconfig=false

clone_and_copy_preset() {
    local repo_url=$1
    local folder_name=$2
    echo -e "${BLUE}📥 Cloning ${folder_name}...${NC}"
    git clone "$repo_url" "../$folder_name" || {
        echo -e "${RED}❌ Failed to clone ${folder_name}.${NC}"; return
    }
    [ -d "../$folder_name/files" ] && mkdir -p files && cp -r "../$folder_name/files/"* files/
    [ -f "../$folder_name/config-nss" ] && cp "../$folder_name/config-nss" .config && skip_menuconfig=true
}

[[ "$preset_choice" == "2" || "$preset_choice" == "5" ]] && clone_and_copy_preset "https://github.com/BootLoopLover/preset.git" "preset-openwrt"
[[ "$preset_choice" == "3" || "$preset_choice" == "5" ]] && clone_and_copy_preset "https://github.com/BootLoopLover/preset.git" "preset-immortalwrt"
[[ "$preset_choice" == "4" || "$preset_choice" == "5" ]] && clone_and_copy_preset "https://github.com/BootLoopLover/preset.git" "preset-nss"

# === 🔁 Re-update Feeds ===
echo -e "${BLUE}🔄 Re-updating feeds...${NC}"
./scripts/feeds update -a
./scripts/feeds install -a

# === ⚙️ Configuration ===
if [ "$skip_menuconfig" = false ]; then
    echo -e "${BLUE}🛠️ Launching menuconfig...${NC}"
    make menuconfig
else
    echo -e "${BLUE}✅ Using preseeded .config. Skipping menuconfig.${NC}"
fi

# === 🔨 Build Process ===
echo -e "${BLUE}🏗️ Starting the build...${NC}"
start_time=$(date +%s)

if make -j$(nproc); then
    echo -e "${GREEN}✅ Build completed successfully.${NC}"
else
    echo -e "${RED}⚠️ Initial build failed. Retrying with verbose output...${NC}"
    make -j1 V=s
    echo -e "${RED}⚠️ Build completed with warnings or errors.${NC}"
fi

# === ⏱️ Build Time ===
end_time=$(date +%s)
duration=$((end_time - start_time))
echo -e "${BLUE}🕒 Build duration: $((duration / 3600)) hour(s) and $(((duration % 3600) / 60)) minute(s).${NC}"

# === 🧹 Clean Up ===
cd ..
echo -e "${BLUE}🧽 Cleaning up script file: $script_file${NC}"
rm -f "$script_file"
