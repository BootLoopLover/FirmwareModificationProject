#!/bin/bash

# =======================================
# 🚀 UNIVERSAL OpenWrt/LEDE BUILDER
# By: BootLoopLover (Technician Edition)
# =======================================

set -e
source /etc/os-release

# === 🎨 Color Definitions ===
RED="\e[31m"; GREEN="\e[32m"; YELLOW="\e[33m"; BLUE="\e[34m"; NC="\e[0m"

# === 🏁 Banner ===
echo -e "${BLUE}=========================================="
echo -e " 🌐 UNIVERSAL OpenWrt/LEDE BUILDER"
echo -e " ⚙️  Professional Technician Edition"
echo -e "==========================================${NC}"

# === 🧱 Build Mode Selection ===
echo "1) 🆕 Fresh Build"
echo "2) 🔁 Rebuild (Existing Build Folder)"
read -p "🔢 Select build mode [1-2]: " build_mode

if [[ "$build_mode" == "1" ]]; then
    # Fresh Build
    read -p "📁 Enter new build directory name: " build_dir
    if [[ -d "$build_dir" ]]; then
        echo -e "${YELLOW}⚠️ Directory '$build_dir' already exists. Please remove or choose another.${NC}"
        exit 1
    fi
    mkdir -p "$build_dir"
    cd "$build_dir"
    
    # Distro selection & clone
    echo -e "${BLUE}Select OpenWrt source:${NC}"
    echo "1) openwrt"
    echo "2) openwrt-ipq"
    echo "3) immortalwrt"
    read -p "🔢 Select distro [1-3]: " distro
    case "$distro" in
        1) git_url="https://github.com/openwrt/openwrt";;
        2) git_url="https://github.com/qosmio/openwrt-ipq";;
        3) git_url="https://github.com/immortalwrt/immortalwrt";;
        *) echo -e "${RED}Invalid distro selection.${NC}"; exit 1;;
    esac
    
    echo -e "${BLUE}Cloning repo from $git_url ...${NC}"
    git clone "$git_url" . || { echo -e "${RED}❌ Git clone failed.${NC}"; exit 1; }
    
    # Git tag selection
    echo -e "${YELLOW}Fetching git tags...${NC}"
    mapfile -t tag_list < <(git tag -l | sort -Vr)
    if [ ${#tag_list[@]} -eq 0 ]; then
        echo -e "${YELLOW}No tags found, continuing with default branch.${NC}"
    else
        for i in "${!tag_list[@]}"; do
            echo "$((i+1))) ${tag_list[$i]}"
        done
        read -p "🔢 Select tag to checkout [1-${#tag_list[@]}]: " tag_index
        git checkout "${tag_list[$((tag_index-1))]}"
    fi

elif [[ "$build_mode" == "2" ]]; then
    # Rebuild
    read -p "📁 Enter existing build directory path: " build_dir
    if [[ ! -d "$build_dir" ]]; then
        echo -e "${RED}❌ Directory '$build_dir' does not exist.${NC}"
        exit 1
    fi
    cd "$build_dir"
    
    echo -e "${GREEN}✅ Rebuilding in existing directory: $build_dir${NC}"

else
    echo -e "${RED}Invalid build mode selected.${NC}"
    exit 1
fi

# === ➕ Add-On Feeds ===
echo -e "${BLUE}Select additional feeds to include:${NC}"
echo "1) ❌ None"
echo "2) 🧪 Custom Feed"
echo "3) 🐘 PHP7 Feed"
echo "4) 🌐 Both Custom & PHP7"
read -p "🔢 Select feed option [1-4]: " feed_choice
case $feed_choice in
    2) echo "src-git custom https://github.com/BootLoopLover/openwrt-package" >> feeds.conf.default;;
    3) echo "src-git php7 https://github.com/BootLoopLover/openwrt-php7" >> feeds.conf.default;;
    4) echo "src-git custom https://github.com/BootLoopLover/openwrt-package" >> feeds.conf.default
       echo "src-git php7 https://github.com/BootLoopLover/openwrt-php7" >> feeds.conf.default;;
esac

# === ♻️ Update & Install Feeds ===
echo -e "${BLUE}🔄 Updating and installing feeds...${NC}"
./scripts/feeds update -a && ./scripts/feeds install -a

# === 📥 Clone Preset & Copy Config ===
if [[ ! -d "../preset" ]]; then
    echo -e "${BLUE}Cloning preset repository...${NC}"
    git clone "https://github.com/BootLoopLover/preset.git" "../preset" || {
        echo -e "${RED}❌ Failed to clone preset.${NC}"; exit 1;
    }
fi

echo -e "${BLUE}Available presets:${NC}"
mapfile -t folders < <(find ../preset -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
for i in "${!folders[@]}"; do
    echo "$((i+1))) ${folders[$i]}"
done

read -p "🔢 Select preset folder to use [1-${#folders[@]}]: " preset_choice
selected_folder="../preset/${folders[$((preset_choice-1))]}"
cp -rf "$selected_folder"/* ./

if [[ -f "$selected_folder/config-nss" ]]; then
    echo -e "${GREEN}📝 Found config-nss, copying to .config...${NC}"
    cp "$selected_folder/config-nss" .config
fi

# === 🛠️ Menuconfig (if no .config) ===
if [[ ! -f .config ]]; then
    echo -e "${YELLOW}⚠️ No .config found. Launching menuconfig...${NC}"
    make menuconfig
fi

# === 🔨 Start Build with Retry ===
echo -e "${BLUE}🚀 Starting build process...${NC}"
make -j$(nproc) || make V=s

# === ⏱️ Build Complete ===
echo -e "${GREEN}✅ Build completed successfully.${NC}"
