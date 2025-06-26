#!/bin/bash
#--------------------------------------------------------
# 🚀 Universal OpenWrt Builder - Final Professional Version
# 👨‍💻 Author: Pakalolo Waraso
#--------------------------------------------------------

# === Terminal Colors ===
BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

trap "echo -e '\n${RED}🚫 Operation cancelled by user.${NC}'; exit 1" SIGINT

# === Branding Banner ===
show_banner() {
    clear
    message="🚀 Launching Arcadyan Firmware Project by Pakalolo Waraso..."
    for ((i=0; i<${#message}; i++)); do
        echo -ne "${YELLOW}${message:$i:1}${NC}"
        sleep 0.01
    done
    echo -e "\n"
    for i in $(seq 1 60); do echo -ne "${BLUE}=${NC}"; sleep 0.005; done
    echo -e "\n"
    echo -e "${BLUE}"
    cat << "EOF"  
   ___       __        __     __                       
  / _ \___ _/ /_____ _/ /__  / /__    
 / ___/ _ `/  '_/ _ `/ / _ \/ / _ \   
/_/   \_,_/_/\_\\_,_/_/\___/_/\___/  
  / _ \_______    (_)__ ____/ /_       
 / ___/ __/ _ \  / / -_) __/ __/  _ _ _ 
/_/  /_/  \___/_/ /\__/\__/\__/  (_|_|_)
             |___/ © Project by Pakalolo
EOF
    echo -e "${NC}"
    for i in $(seq 1 60); do echo -ne "${BLUE}-${NC}"; sleep 0.005; done
    echo -e "\n"

    echo "========================================================="
    echo -e "📦 ${BLUE}Universal OpenWrt/ImmortalWrt/OpenWrt-IPQ/LEDE Builder${NC}"
    echo "========================================================="
    echo -e "👤 ${BLUE}Author   : Pakalolo Waraso${NC}"
    echo -e "🌐 ${BLUE}GitHub   : https://github.com/BootLoopLover${NC}"
    echo -e "💬 ${BLUE}Telegram : t.me/PakaloloWaras0${NC}"
    echo "========================================================="
}

# === Apply LEDE Patch ===
apply_lede_patch() {
    echo -e "${YELLOW}🔧 Applying LEDE-specific patch...${NC}"
    if [ -d "target/linux/qualcommax" ]; then
        if [ -f "target/linux/qualcommax/patches-6.6/0400-mtd-rawnand-add-support-for-TH58NYG3S0HBAI4.patch" ]; then
            mkdir -p target/linux/qualcommax/patches-6.1/
            if cp -v target/linux/qualcommax/patches-6.6/0400-mtd-rawnand-add-support-for-TH58NYG3S0HBAI4.patch \
                   target/linux/qualcommax/patches-6.1/; then
                echo -e "${GREEN}✅ Patch copied successfully.${NC}"
            else
                echo -e "${RED}❌ Failed to copy patch.${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️ Patch file not found, skipping.${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ Directory target/linux/qualcommax not found, skipping patch.${NC}"
    fi
}

# === Git Tag Selection ===
checkout_tag() {
    echo -e "${YELLOW}🔍 Fetching available Git tags...${NC}"
    mapfile -t tag_list < <(git tag -l | sort -Vr)
    if [[ ${#tag_list[@]} -eq 0 ]]; then
        echo -e "${YELLOW}⚠️ No tags available. Proceeding with default branch.${NC}"
    else
        for i in "${!tag_list[@]}"; do
            echo "$((i+1))) ${tag_list[$i]}"
        done
        read -p "🔖 Select tag [1-${#tag_list[@]}], press Enter to skip: " tag_index
        if [[ -n "$tag_index" ]]; then
            checked_out_tag="${tag_list[$((tag_index-1))]}"
            git checkout "$checked_out_tag"
        fi
    fi
}

# === Feed Selection Menu ===
add_feeds() {
    echo -e "${BLUE}Select additional feeds:${NC}"
    printf "1) ❌  %-25s\n" "No additional feeds"
    printf "2) 🧪  %-25s\n" "Custom Feed (BootLoopLover)"
    printf "3) 🐘  %-25s\n" "PHP7 Feed (BootLoopLover)"
    printf "4) 🌐  %-25s\n" "Custom + PHP7"
    echo "========================================================="
    read -p "🔹 Select [1-4]: " feed_choice

    case "$feed_choice" in
        2)
            echo "src-git custom https://github.com/BootLoopLover/custom-package" >> feeds.conf.default
            ;;
        3)
            echo "src-git php7 https://github.com/BootLoopLover/openwrt-php7-package" >> feeds.conf.default
            ;;
        4)
            echo "src-git custom https://github.com/BootLoopLover/custom-package" >> feeds.conf.default
            echo "src-git php7 https://github.com/BootLoopLover/openwrt-php7-package" >> feeds.conf.default
            ;;
        1) ;; # No additional feed
        *) echo -e "${RED}❌ Invalid selection.${NC}"; exit 1 ;;
    esac

    echo -e "${GREEN}🔄 Updating feeds...${NC}"
    ./scripts/feeds update -a && ./scripts/feeds install -a -f
}

# === Preset Configuration Selection ===
use_preset_menu() {
    echo -e "${BLUE}Use a preset configuration?${NC}"
    echo "1) ✅ Yes (recommended)"
    echo "2) 🏗️ No (open menuconfig manually)"
    read -p "🔹 Select [1-2]: " preset_answer

    if [[ "$preset_answer" == "1" ]]; then
        if [[ ! -d "../preset" ]]; then
            echo -e "${YELLOW}📦 Cloning preset configurations...${NC}"
            if ! git clone "https://github.com/BootLoopLover/preset.git" "../preset"; then
                echo -e "${RED}❌ Failed to clone presets. Launching menuconfig instead.${NC}"
                make menuconfig
                return
            fi
        fi
        echo -e "${BLUE}📂 Available presets:${NC}"
        mapfile -t folders < <(find ../preset -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
        if [[ ${#folders[@]} -eq 0 ]]; then
            echo -e "${RED}❌ No preset folders found. Launching menuconfig.${NC}"
            make menuconfig
            return
        fi
        for i in "${!folders[@]}"; do
            echo "$((i+1))) ${folders[$i]}"
        done
        read -p "🔹 Select preset folder [1-${#folders[@]}]: " preset_choice
        selected_folder="../preset/${folders[$((preset_choice-1))]}"
        cp -rf "$selected_folder"/* ./
        [[ -f "$selected_folder/config-nss" ]] && cp "$selected_folder/config-nss" .config
    else
        [[ ! -f .config ]] && make menuconfig
    fi
}

# === Build Action Menu ===
build_action_menu() {
    echo -e "\n📋 ${BLUE}Build Menu:${NC}"
    printf "1) 🔄  %-30s\n" "Update feeds"
    printf "2) 🧪  %-30s\n" "Update feeds + menuconfig"
    printf "3) 🛠️  %-30s\n" "Run menuconfig"
    printf "4) 🏗️  %-30s\n" "Start build"
    printf "5) 🔙  %-30s\n" "Back to main menu"
    printf "6) ❌  %-30s\n" "Exit"
    echo "========================================================="
    read -p "🔹 Select [1-6]: " choice
    case "$choice" in
        1) ./scripts/feeds update -a && ./scripts/feeds install -a ;;
        2) ./scripts/feeds update -a && ./scripts/feeds install -a; make menuconfig ;;
        3) make menuconfig ;;
        4) return 0 ;;
        5) cd ..; return 1 ;;
        6) echo -e "${GREEN}🙋 Exiting.${NC}"; exit 0 ;;
        *) echo -e "${RED}⚠️ Invalid input.${NC}" ;;
    esac
    return 1
}

# === Build Process ===
start_build() {
    echo -e "${GREEN}🚀 Starting firmware build...${NC}"
    start_time=$(date +%s)
    if make -j5 > build.log 2>&1; then
        echo -e "${GREEN}✅ Build completed successfully!${NC}"
    else
        echo -e "${RED}⚠️ Build failed. Retrying with verbose output...${NC}"
        make -j5 V=s | tee build-error.log
    fi
    end_time=$(date +%s)
    elapsed=$((end_time - start_time))
    echo -e "${BLUE}⏱️ Build completed in $((elapsed / 60)) minutes $((elapsed % 60)) seconds.${NC}"
    command -v notify-send &>/dev/null && notify-send "OpenWrt Build" "✅ Build finished in: $(pwd)"
}

# === Fresh Build Menu ===
fresh_build() {
    echo -e "\n📁 Select build directory:"
    printf "1) %-20s 3) %s\n" "openwrt"       "openwrt-ipq (qosmio)"
    printf "2) %-20s 4) %s\n" "immortalwrt"   "lede (coolsnowwolf)"

    while true; do
        read -p "🔹 Select [1-4]: " choice
        case "$choice" in
            1) folder_name="openwrt";       git_url="https://github.com/openwrt/openwrt";;
            2) folder_name="immortalwrt";   git_url="https://github.com/immortalwrt/immortalwrt";;
            3) folder_name="openwrt-ipq";   git_url="https://github.com/qosmio/openwrt-ipq";;
            4) folder_name="lede";          git_url="https://github.com/coolsnowwolf/lede.git";;
            *) echo -e "${RED}❌ Invalid selection.${NC}"; continue;;
        esac
        break
    done

    echo -e "\n📂 Selected directory: ${YELLOW}$folder_name${NC}"
    mkdir -p "$folder_name" && cd "$folder_name" || { echo -e "${RED}❌ Failed to enter directory.${NC}"; exit 1; }

    echo -e "🔗 Cloning from: ${GREEN}$git_url${NC}"
    if [[ "$folder_name" == "openwrt-ipq" ]]; then
        git clone "$git_url" -b 24.10-nss . || { echo -e "${RED}❌ Failed to clone repo.${NC}"; exit 1; }
    else
        git clone "$git_url" . || { echo -e "${RED}❌ Failed to clone repo.${NC}"; exit 1; }
    fi

    [[ "$folder_name" == "lede" ]] && apply_lede_patch

    echo -e "${GREEN}🔄 Initial feed update & install...${NC}"
    ./scripts/feeds update -a && ./scripts/feeds install -a

    [[ "$folder_name" != "openwrt-ipq" ]] && checkout_tag
    add_feeds
    use_preset_menu

    if ! grep -q "^CONFIG_TARGET" .config 2>/dev/null; then
        echo -e "${RED}❌ Target board not configured. Launching menuconfig...${NC}"
        make menuconfig
    fi

    start_build
}

# === Rebuild Existing Folder ===
rebuild_mode() {
    while true; do
        show_banner
        echo -e "📂 ${BLUE}Select existing build directory:${NC}"
        mapfile -t folders < <(find . -maxdepth 1 -type d ! -name ".")
        for i in "${!folders[@]}"; do
            echo "$((i+1))) ${folders[$i]##*/}"
        done
        echo "0) Exit"
        read -p "🔹 Select [0-${#folders[@]}]: " choice
        if [[ "$choice" == 0 ]]; then
            echo -e "${GREEN}🙋 Exiting.${NC}"; exit 0
        elif [[ "$choice" =~ ^[0-9]+$ && "$choice" -le "${#folders[@]}" ]]; then
            folder="${folders[$((choice-1))]}"
            cd "$folder" || continue
            while ! build_action_menu; do :; done
            start_build
            break
        else
            echo -e "${RED}⚠️ Invalid selection.${NC}"
        fi
    done
}

# === Main Menu ===
main_menu() {
    show_banner
    echo "1️⃣ Fresh build"
    echo "2️⃣ Rebuild"
    echo "3️⃣ Exit"
    echo "========================================================="
    read -p "🔹 Select option [1-3]: " main_choice
    case "$main_choice" in
        1) fresh_build ;;
        2) rebuild_mode ;;
        3) echo -e "${GREEN}🙋 Exiting.${NC}"; exit 0 ;;
        *) echo -e "${RED}⚠️ Invalid selection.${NC}"; exit 1 ;;
    esac
}

# === Start Script ===
main_menu
