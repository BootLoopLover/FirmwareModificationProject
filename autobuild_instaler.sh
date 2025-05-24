#!/bin/bash
#--------------------------------------------------------
# 🚀 OpenWrt Rebuild Script - Technical Style
# 👨‍💻 Author: Pakalolo Waraso
#--------------------------------------------------------

BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

# === Tampilan Awal ===
clear
echo -e "🛠️  ${BLUE}Universal Compile OpenWrt/ImmortalWrt/OpenWrt-IPQ${NC}"
echo "--------------------------------------------------------"
echo -e "✨ ${BLUE}Firmware Modifications Project${NC}"
echo -e "🌐 ${BLUE}GitHub   : https://github.com/BootLoopLover${NC}"
echo -e "💬 ${BLUE}Telegram : t.me/PakaloloWaras0${NC}"
echo "--------------------------------------------------------"

# === 📁 Buat Folder Build Otomatis ===
read -p "📁 Masukkan nama folder untuk build (default: openwrt_build): " folder_name
folder_name="${folder_name:-openwrt_build}"
mkdir -p "$folder_name" || { echo -e "${RED}❌ Gagal membuat folder build.${NC}"; exit 1; }
cd "$folder_name" || exit 1

# === 📦 Pilih Sumber OpenWrt ===
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

# === 🔖 Pilih Git Tag (Jika Ada) ===
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

# === ➕ Tambahkan Feeds Tambahan ===
echo -e "${BLUE}Select additional feeds to include:${NC}"
echo "1) ❌ None"
echo "2) 🧪 Custom Feed"
echo "3) 🐘 PHP7 Feed"
echo "4) 🌐 Both Custom & PHP7"
read -p "🔢 Select feed option [1-4]: " feed_choice
case $feed_choice in
    2) echo "src-git custom https://github.com/BootLoopLover/custom-package" >> feeds.conf.default;;
    3) echo "src-git php7 https://github.com/BootLoopLover/openwrt-php7-package" >> feeds.conf.default;;
    4) echo "src-git custom https://github.com/BootLoopLover/custom-package" >> feeds.conf.default
       echo "src-git php7 https://github.com/BootLoopLover/openwrt-php7-package" >> feeds.conf.default;;
esac

# === ♻️ Update Feeds ===
echo -e "${BLUE}🔄 Updating and installing feeds...${NC}"
./scripts/feeds update -a && ./scripts/feeds install -a

# === 📥 Clone Preset Config ===
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

# === 🛠️ Menuconfig Jika Tidak Ada Config ===
if [[ ! -f .config ]]; then
    echo -e "${YELLOW}⚠️ No .config found. Launching menuconfig...${NC}"
    make menuconfig
fi

# === ⏱️ Mulai Build dengan Stopwatch ===
echo -e "${BLUE}🚀 Starting build process...${NC}"
start_time=$(date +%s)

make -j$(nproc) || make V=s

end_time=$(date +%s)
duration=$((end_time - start_time))
echo -e "${GREEN}✅ Build completed successfully in ${duration} seconds.${NC}"

# === 🧹 Hapus Skrip Ini ===
script_name=$(basename "$0")
echo -e "${RED}🧹 Deleting script: ${script_name}${NC}"
rm -f "$script_name"
