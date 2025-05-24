#!/bin/bash

# ================================
# 🚀 UNIVERSAL OpenWrt BUILDER
# ================================
# Supported:
# - OpenWrt, ImmortalWrt, OpenWrt-IPQ
# - Preset Config (with optional auto .config)
# - Additional Feeds: custom, php7
# - Menuconfig & Build (with retry)
# ================================

set -e
source /etc/os-release

# === 🎨 Colors ===
RED="\e[31m"; GREEN="\e[32m"; YELLOW="\e[33m"; BLUE="\e[34m"; NC="\e[0m"

# === 🏁 Initial Banner ===
echo -e "${BLUE}=============================="
echo -e "  🌐 UNIVERSAL OpenWrt BUILDER"
echo -e "  🛠️  By BootLoopLover"
echo -e "==============================${NC}"

# === 🧱 Build Mode ===
echo "1) 🆕 Fresh Build"
echo "2) 🔁 Rebuild"
echo "==================="
read -p "🔢 Select build mode [1-2]: " build_mode

if [[ "$build_mode" == "1" ]]; then
    read -p "📁 Enter folder name for fresh build: " build_dir
    mkdir -p "$build_dir" && cd "$build_dir"

    echo "1) openwrt"
    echo "2) openwrt-ipq"
    echo "3) immortalwrt"
    read -p "🔢 Select distro [1-3]: " distro

    case "$distro" in
        1) git_url="https://github.com/openwrt/openwrt";;
        2) git_url="https://github.com/qosmio/openwrt-ipq";;
        3) git_url="https://github.com/immortalwrt/immortalwrt";;
        *) echo -e "${RED}Invalid distro selected.${NC}"; exit 1;;
    esac

    git clone ${branch:+-b $branch} "$git_url" .
else
    read -p "📁 Enter existing build folder: " build_dir
    cd "$build_dir"
fi

# === 🧩 Feeds Option ===
echo "========== 🧩 Feeds Menu =========="
echo "1) ❌ None"
echo "2) 🧪 Custom Feed"
echo "3) 🐘 PHP7 Feed"
echo "4) 🌐 All Feeds"
echo "=================================="
read -p "🔢 Select feed option [1-4]: " feed_choice

case $feed_choice in
    2) echo "src-git custom https://github.com/BootLoopLover/openwrt-package" >> feeds.conf.default;;
    3) echo "src-git php7 https://github.com/BootLoopLover/openwrt-php7" >> feeds.conf.default;;
    4) echo "src-git custom https://github.com/BootLoopLover/openwrt-package" >> feeds.conf.default
       echo "src-git php7 https://github.com/BootLoopLover/openwrt-php7" >> feeds.conf.default;;
esac

# === 🗂️ Preset Configuration ===
echo "========== ⚙️ Preset Menu =========="
echo "1) ❌ None"
echo "2) 📜 preset"
echo "=================================="
read -p "🔢 Select preset option [1-2]: " preset_choice

skip_menuconfig=false

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
    else
        echo -e "${RED}❌ Invalid selection. Skipping folder copy.${NC}"
        return 1
    fi
}

if [[ "$preset_choice" == "2" ]]; then
    clone_and_copy_preset "https://github.com/BootLoopLover/preset.git" "preset"
elif [[ "$preset_choice" == "1" ]]; then
    echo "⚠️ No preset selected."
else
    echo -e "${RED}❌ Invalid preset choice. Exiting.${NC}"
    exit 1
fi

# --- AUTO COPY preset-nss dan config-nss ke build folder jika ada ---
if [[ -d "../preset-nss" ]]; then
    echo -e "${BLUE}📥 Found 'preset-nss' folder. Copying content...${NC}"
    cp -rf ../preset-nss/* ./
    if [[ -f "../preset-nss/config-nss" ]]; then
        echo -e "${BLUE}📝 Found 'config-nss'. Copying as .config...${NC}"
        cp ../preset-nss/config-nss .config
        skip_menuconfig=true
    fi
fi

# === 🚀 Build Process ===
./scripts/feeds update -a && ./scripts/feeds install -a

if [ "$skip_menuconfig" = false ]; then
    make menuconfig
fi

# === 🔨 Build with retry ===
make -j$(nproc) || make V=s

# === ⏱️ Build Time ===
echo -e "${GREEN}✅ Build complete.${NC}"
