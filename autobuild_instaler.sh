#!/bin/bash
#--------------------------------------------------------
# 🚀 Universal OpenWrt Builder - Final Professional Version
# 👨‍💻 Author: SopekSemprit 
#--------------------------------------------------------

BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

show_banner() {
    clear
    # Efek ketikan awal
    message="🚀 Launching Arcadyan Firmware Project by Sopek Semprit..."
    for ((i=0; i<${#message}; i++)); do
        echo -ne "${YELLOW}${message:$i:1}${NC}"
        sleep 0.01
    done
    echo -e "\n"
    # Garis animasi horizontal (simulasi loading)
    for i in $(seq 1 60); do
        echo -ne "${BLUE}=${NC}"
        sleep 0.005
    done
    echo -e "\n"
    # ASCII Banner dengan warna biru
    echo -e "${BLUE}"
    cat << "EOF"
   ___                   __                 
  / _ | ___________ ____/ /_ _____ ____   
 / __ |/ __/ __/ _ `/ _  / // / _ `/ _ \  
/_/ |_/_/  \__/\_,_/\_,_/\_, /\_,_/_//_/ 
   _____                /___/     
  / __(_)_____ _ _    _____ ________ 
 / _// / __/  ' \ |/|/ / _ `/ __/ -_)
/_/ /_/_/ /_/_/_/__,__/\_,_/_/  \__/            
   ___             _         __        
  / _ \_______    (_)__ ____/ /_       
 / ___/ __/ _ \  / / -_) __/ __/  _ _ _ 
/_/  /_/  \___/_/ /\__/\__/\__/  (_|_|_)
             |___/ 
EOF
    echo -e "${NC}"

    # Garis animasi horizontal kedua
    for i in $(seq 1 60); do
        echo -ne "${BLUE}-${NC}"
        sleep 0.005
    done
    echo -e "\n"

    # Informasi branding
    echo "========================================================="
    echo -e "📦 ${BLUE}Universal OpenWrt/ImmortalWrt/OpenWrt-IPQ Builder${NC}"
    echo "========================================================="
    echo -e "👤 ${BLUE}Author   : Sopek Semprit${NC}"
    echo -e "🌐 ${BLUE}GitHub   : https://github.com/BootLoopLover${NC}"
    echo -e "💬 ${BLUE}Telegram : t.me/PakaloloWaras0${NC}"
    echo "========================================================="
}

select_distro() {
    echo -e "${BLUE}Select OpenWrt source:${NC}"
    echo "1) openwrt"
    echo "2) openwrt-ipq"
    echo "3) immortalwrt"
    echo "========================================================="
    read -p "🔢 Select distro [1-3]: " distro
    case "$distro" in
        1) git_url="https://github.com/openwrt/openwrt";;
        2) git_url="https://github.com/qosmio/openwrt-ipq";;
        3) git_url="https://github.com/immortalwrt/immortalwrt";;
        *) echo -e "${RED}❌ Invalid selection.${NC}"; exit 1;;
    esac
}

checkout_tag() {
    echo -e "${YELLOW}Fetching git tags...${NC}"
    mapfile -t tag_list < <(git tag -l | sort -Vr)
    if [[ ${#tag_list[@]} -eq 0 ]]; then
        echo -e "${YELLOW}⚠️ No tags found. Using default branch.${NC}"
    else
        for i in "${!tag_list[@]}"; do
            echo "$((i+1))) ${tag_list[$i]}"
        done
        read -p "🔖 Select tag to checkout [1-${#tag_list[@]}] or press Enter to skip: " tag_index
        [[ -n "$tag_index" ]] && git checkout "${tag_list[$((tag_index-1))]}"
    fi
}

add_feeds() {
    echo -e "${BLUE}Select additional feeds to include:${NC}"
    echo "1) ❌ None"
    echo "2) 🧪 Custom Feed"
    echo "3) 🐘 PHP7 Feed"
    echo "4) 🌐 Both Custom & PHP7"
    echo "========================================================="
    read -p "🔢 Select feed option [1-4]: " feed_choice
    case "$feed_choice" in
        2) echo "src-git custom https://github.com/BootLoopLover/custom-package" >> feeds.conf.default ;;
        3) echo "src-git php7 https://github.com/BootLoopLover/openwrt-php7-package" >> feeds.conf.default ;;
        4)
            echo "src-git custom https://github.com/BootLoopLover/custom-package" >> feeds.conf.default
            echo "src-git php7 https://github.com/BootLoopLover/openwrt-php7-package" >> feeds.conf.default ;;
    esac
}

use_preset_menu() {
    echo -e "${BLUE}Use preset configuration files?${NC}"
    echo "1) ✅ Yes (private use only)"
    echo "2) ❌ No (manual setup)"
    read -p "📌 Choice [1-2]: " preset_answer

    if [[ "$preset_answer" == "1" ]]; then
        [[ ! -d "../preset" ]] && {
            echo -e "${BLUE}Cloning preset repository...${NC}"
            git clone "https://github.com/BootLoopLover/preset.git" "../preset" || {
                echo -e "${RED}❌ Failed to clone preset.${NC}"; exit 1;
            }
        }

        echo -e "${BLUE}Available presets:${NC}"
        mapfile -t folders < <(find ../preset -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
        for i in "${!folders[@]}"; do
            echo "$((i+1))) ${folders[$i]}"
        done
        read -p "🔢 Select preset folder [1-${#folders[@]}]: " preset_choice
        selected_folder="../preset/${folders[$((preset_choice-1))]}"
        cp -rf "$selected_folder"/* ./
        [[ -f "$selected_folder/config-nss" ]] && cp "$selected_folder/config-nss" .config
    else
        [[ ! -f .config ]] && make menuconfig
    fi
}

build_action_menu() {
    echo -e "\n📋 ${BLUE}Select action:${NC}"
    echo "1) 🔄 Update feeds only"
    echo "2) 🔄 Update feeds + menuconfig"
    echo "3) 🛠️  Run menuconfig only"
    echo "4) 🏗️  Proceed to build"
    echo "5) 🔙 Back"
    echo "6) ❌ Exit"
    echo "========================================================="
    read -p "📌 Choice [1-6]: " choice
    case "$choice" in
        1) ./scripts/feeds update -a && ./scripts/feeds install -a ;;
        2) ./scripts/feeds update -a && ./scripts/feeds install -a; make menuconfig ;;
        3) make menuconfig ;;
        4) return 0 ;;
        5) cd ..; return 1 ;;
        6) echo -e "${GREEN}👋 Exit.${NC}"; exit 0 ;;
        *) echo -e "${RED}⚠️ Invalid input.${NC}" ;;
    esac
    return 1
}

start_build() {
    echo -e "${GREEN}🚀 Starting build...${NC}"
    start_time=$(date +%s)
    if make -j$(nproc); then
        echo -e "${GREEN}✅ Build success!${NC}"
    else
        echo -e "${RED}⚠️ Build failed, retrying...${NC}"
        make -j1 V=s
    fi
    end_time=$(date +%s)
    elapsed=$((end_time - start_time))
    echo -e "${BLUE}⏱️ Build completed in $((elapsed / 60)) minute(s) and $((elapsed % 60)) second(s).${NC}"
}

fresh_build() {
    echo -e "\n📁 Pilih nama folder build:"
    options=("openwrt" "immortalwrt" "openwrt-ipq" "Custom (masukkan sendiri)")
    select folder_option in "${options[@]}"; do
        case $REPLY in
            1)
                folder_name="openwrt"
                git_url="https://github.com/openwrt/openwrt"
                break
                ;;
            2)
                folder_name="immortalwrt"
                git_url="https://github.com/immortalwrt/immortalwrt"
                break
                ;;
            3)
                folder_name="openwrt-ipq"
                git_url="https://github.com/qosmio/openwrt-ipq"
                break
                ;;
            4)
                read -p "Masukkan nama folder build kustom: " custom_name
                folder_name="${custom_name:-custom_build}"
                select_distro  # hanya kalau custom
                break
                ;;
            *)
                echo -e "${RED}❌ Pilihan tidak valid.${NC}"
                ;;
        esac
    done

    mkdir -p "$folder_name" || { echo -e "${RED}❌ Gagal membuat folder.${NC}"; exit 1; }
    cd "$folder_name" || exit 1

    echo -e "🔗 Cloning dari: $git_url"
    git clone "$git_url" . || { echo -e "${RED}❌ Git clone gagal.${NC}"; exit 1; }

    checkout_tag
    add_feeds
    ./scripts/feeds update -a && ./scripts/feeds install -a
    use_preset_menu
    start_build
}



rebuild_mode() {
    while true; do
        show_banner
        echo -e "📂 ${BLUE}Select existing build folder:${NC}"
        mapfile -t folders < <(find . -maxdepth 1 -type d \( ! -name . \))
        for i in "${!folders[@]}"; do
            echo "$((i+1))) ${folders[$i]##*/}"
        done
        echo "❌ 0) Exit"
        read -p "📌 Choice [0-${#folders[@]}]: " choice

        if [[ "$choice" == 0 ]]; then
            echo -e "${GREEN}👋 Exiting...${NC}"; exit 0
        elif [[ "$choice" =~ ^[0-9]+$ && "$choice" -le "${#folders[@]}" ]]; then
            folder="${folders[$((choice-1))]}"
            cd "$folder" || continue
            while ! build_action_menu; do :; done
            start_build
            break
        else
            echo -e "${RED}⚠️ Invalid choice. Try again.${NC}"
        fi
    done
}

main_menu() {
    show_banner
    echo "1️⃣ Fresh build (baru)"
    echo "2️⃣ Rebuild existing folder"
    echo "3️⃣ ❌ Exit"
    echo "========================================================="
    read -p "📌 Select option [1-3]: " main_choice
    case "$main_choice" in
        1) fresh_build ;;
        2) rebuild_mode ;;
        3) echo -e "${GREEN}👋 Exiting...${NC}"; exit 0 ;;
        *) echo -e "${RED}⚠️ Invalid choice.${NC}"; exit 1 ;;
    esac
}

# === Run ===
main_menu
