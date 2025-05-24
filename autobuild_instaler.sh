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

# === 🔧 Internet Check ===
ping -c 1 github.com > /dev/null 2>&1 || {
    echo -e "${RED}❌ No internet connection. Please check your network.${NC}"
    exit 1
}

# === ⚙️ Variables ===
preset_folder="preset"
script_file="$(basename "$0")"

# === 👋 Welcome Message ===
clear
echo "========== 🧰 Universal OpenWrt/ImmortalWrt/OpenWrt-IPQ Builder =========="
echo -e "${BLUE}🔧 Firmware Modifications Project${NC}"
echo -e "${BLUE}🌐 GitHub : https://github.com/BootLoopLover${NC}"
echo -e "${BLUE}💬 Telegram : t.me/PakaloloWaras0${NC}"
echo "====================================================================="
echo -e "${BLUE}🔁 Select build mode:${NC}"
echo "1) 🆕 Fresh Build"
echo "2) 🔁 Rebuild Existing Source"
echo "====================================================================="
read -p "🔢 Enter your choice [1/2]: " build_mode

if [[ "$build_mode" == "2" ]]; then
    echo -e "${BLUE}📂 Existing folders detected:${NC}"
    for d in */; do [[ -d "$d/.git" ]] && echo " - ${d%/}"; done
    read -p "📂 Enter the name of existing build folder: " distro
    if [[ ! -d "$distro" ]]; then
        echo -e "${RED}❌ Folder '$distro' not found. Exiting.${NC}"
        exit 1
    fi
    cd "$distro" || { echo -e "${RED}❌ Failed to enter directory '$distro'.${NC}"; exit 1; }

    echo -e "${GREEN}🔁 Rebuilding from existing folder '$distro'...${NC}"
    ./scripts/feeds update -a
    ./scripts/feeds install -a
    make menuconfig
    make -j$(nproc)
    exit 0
fi

# === 📦 Select Distribution ===
echo -e "${BLUE}📦 Select the firmware distribution to build:${NC}"
echo "1) 🐧 OpenWrt"
echo "2) 🚀 OpenWrt-IPQ"
echo "3) 🛡️ ImmortalWrt"
echo "====================================================================="
read -p "🔢 Enter your choice [1/2/3]: " choice

case "$choice" in
    1)
        distro="openwrt"
        repo="https://github.com/openwrt/openwrt.git"
        ;;
    2)
        distro="openwrt-ipq"
        repo="https://github.com/qosmio/openwrt-ipq.git"
        ;;
    3)
        distro="immortalwrt"
        repo="https://github.com/immortalwrt/immortalwrt.git"
        ;;
    *)
        echo -e "${RED}❌ Invalid choice. Exiting.${NC}"
        exit 1
        ;;
esac

# === 📥 Dependency Installation ===
deps="build-essential clang flex bison g++ gawk gcc-multilib g++-multilib gettext git libncurses5-dev libssl-dev python3-setuptools rsync swig unzip zlib1g-dev file wget"
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

# === 🍳 Git Tag/Branch Selection ===
echo -e "${BLUE}🌿 Available Git tags:${NC}"
git tag | sort -V
read -p "🔖 Enter tag to checkout (leave empty for default branch): " TARGET_TAG
[[ -n "$TARGET_TAG" ]] && git fetch --tags && git checkout "$TARGET_TAG"

branch_name="build-$(date +%Y%m%d-%H%M)"
echo -e "${BLUE}🌿 Creating new branch: $branch_name${NC}"
git switch -c "$branch_name"

# === 🍻 Feed Update ===
echo -e "${BLUE}🔁 Updating and installing feeds...${NC}"
./scripts/feeds update -a
./scripts/feeds install -a

# === 🍟 Additional Feeds ===
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
        echo 'src-git php7 https://github.com/BootLoopLover/openwrt-php7-package.git' >> feeds.conf.default ;;
    *) echo "⚠️ No feeds added." ;;
esac

read -p "⏸️ Press [Enter] to continue after modifying feeds..." temp

# === 🗂️ Preset Configuration ===
echo "========== ⚙️ Preset Menu =========="
echo "1) ❌ None"
echo "2) 📜 preset"
echo "=================================="
read -p "🔢 Select preset option [1-2]: " preset_choice

clone_and_copy_preset() {
    local repo_url=$1
    local folder_name=$2
    echo -e "${BLUE}📥 Cloning ${folder_name}...${NC}"
    git clone "$repo_url" "../$folder_name" || {
        echo -e "${RED}❌ Failed to clone ${folder_name}.${NC}"; return 1
    }

    echo -e "${BLUE}📁 Available folders in $folder_name:${NC}"
    mapfile -t folders < <(find "../$folder_name" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)

    if [[ ${#folders[@]} -eq 0 ]]; then
        echo -e "${RED}⚠️ No folders found in $folder_name.${NC}"
        return 1
    fi

    for i in "${!folders[@]}"; do
        echo "$((i+1))) ${folders[$i]}"
    done

    read -p "🔢 Select folder to copy [1-${#folders[@]}]: " folder_choice
    selected_folder="../$folder_name/${folders[$((folder_choice-1))]}"

    if [[ -d "$selected_folder" ]]; then
        echo -e "${GREEN}📂 Copying from folder: ${folders[$((folder_choice-1))]}${NC}"
        cp -rf "$selected_folder"/* ./
        return 0
    else
        echo -e "${RED}❌ Invalid selection. Skipping folder copy.${NC}"
        return 1
    fi
}

skip_menuconfig=false

if [[ "$preset_choice" == "2" ]]; then
    clone_and_copy_preset "https://github.com/BootLoopLover/preset.git" "preset-openwrt"
elif [[ "$preset_choice" == "1" ]]; then
    echo "⚠️ No preset selected."
else
    echo -e "${RED}❌ Invalid preset choice. Exiting.${NC}"
    exit 1
fi

# --- AUTO COPY preset-nss dan config-nss ke build folder jika ada ---
if [[ -d "../preset-nss" ]]; then
    echo -e "${BLUE}📥 Found 'preset-nss' folder. Copying content including config-nss...${NC}"
    cp -rf ../preset-nss/* ./
    if [[ -f "../preset-nss/config-nss" ]]; then
        echo -e "${BLUE}📝 Copying config-nss as .config...${NC}"
        cp ../preset-nss/config-nss .config
        skip_menuconfig=true
    fi
fi

# === 🔄 Re-update Feeds ===
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

LOG_FILE="build-$(date +%Y%m%d-%H%M).log"
if make -j$(nproc) 2>&1 | tee "$LOG_FILE"; then
    echo -e "${GREEN}✅ Build completed successfully. Log: ${LOG_FILE}${NC}"
else
    echo -e "${RED}⚠ Initial build failed. Retrying with verbose output...${NC}"
    make -j1 V=s 2>&1 | tee "$LOG_FILE"
    echo -e "${RED}⚠ Build completed with warnings or errors. Log: ${LOG_FILE}${NC}"
fi

# === ⏱️ Build Time ===
end_time=$(date +%s)
duration=$((end_time - start_time))
echo -e "${BLUE}🕒 Build duration: $((duration / 3600)) hour(s) and $(((duration % 3600) / 60)) minute(s).${NC}"

# === 🧽 Clean Up ===
cd ..
echo -e "${BLUE}🧽 Cleaning up script file: $script_file${NC}"
rm -f "$script_file"

read -p "📁 Open build folder? (y/n): " open_folder
[[ "${open_folder,,}" =~ ^(y|yes)$ ]] && xdg-open "$distro/bin" || echo -e "${BLUE}👋 Done.${NC}"
