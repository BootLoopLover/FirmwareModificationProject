#!/bin/bash
#--------------------------------------------------------
# 🚀 Universal OpenWrt Builder - Final Professional Version
# 👨‍💻 Author: Pakalolo Waraso
#--------------------------------------------------------

# === Warna Terminal ===
BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

trap "echo -e '\n${RED}🚫 Dihentikan oleh pengguna.${NC}'; exit 1" SIGINT

# === Banner Branding ===
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
    for i in $(seq 1 60); do echo -ne "${BLUE}-${NC}"; sleep 0.005; done
    echo -e "\n"

    echo "========================================================="
    echo -e "📦 ${BLUE}Universal OpenWrt/ImmortalWrt/OpenWrt-IPQ Builder${NC}"
    echo "========================================================="
    echo -e "👤 ${BLUE}Author   : Pakalolo Waraso${NC}"
    echo -e "🌐 ${BLUE}GitHub   : https://github.com/BootLoopLover${NC}"
    echo -e "💬 ${BLUE}Telegram : t.me/PakaloloWaras0${NC}"
    echo "========================================================="
}

# === Tambahan Fungsi Patch LEDE ===
apply_lede_patch() {
    echo -e "${YELLOW}🔧 Applying LEDE-specific patch...${NC}"
    if [ -d "target/linux/qualcommax" ]; then
        if [ -f "target/linux/qualcommax/patches-6.6/0400-mtd-rawnand-add-support-for-TH58NYG3S0HBAI4.patch" ]; then
            mkdir -p target/linux/qualcommax/patches-6.1/
            if cp -v target/linux/qualcommax/patches-6.6/0400-mtd-rawnand-add-support-for-TH58NYG3S0HBAI4.patch \
                   target/linux/qualcommax/patches-6.1/0400-mtd-rawnand-add-support-for-TH58NYG3S0HBAI4.patch; then
                echo -e "${GREEN}✅ Patch copied successfully${NC}"
            else
                echo -e "${RED}❌ Failed to copy patch${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️ Patch file tidak ditemukan, dilewati${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ Folder target/linux/qualcommax tidak ditemukan, patch dilewati${NC}"
    fi
}


select_distro() {
    echo -e "${BLUE}Pilih sumber OpenWrt:${NC}"
    printf "1) 🏳️  %-15s\n" "openwrt"
    printf "2) 🔧  %-15s\n" "openwrt-ipq"
    printf "3) 💀  %-15s\n" "immortalwrt"
    printf "4) 🏳️  %-15s\n" "lede"
    echo "========================================================="
    read -p "🔹 Pilihan [1-3]: " distro
    case "$distro" in
        1) git_url="https://github.com/openwrt/openwrt";;
        2) git_url="https://github.com/qosmio/openwrt-ipq";;
        3) git_url="https://github.com/immortalwrt/immortalwrt";;
        4) git_url="https://github.com/coolsnowwolf/lede";;
        *) echo -e "${RED}❌ Pilihan tidak valid.${NC}"; exit 1;;
    esac
}

checkout_tag() {
    echo -e "${YELLOW}🔍 Mengambil daftar git tag...${NC}"
    mapfile -t tag_list < <(git tag -l | sort -Vr)
    if [[ ${#tag_list[@]} -eq 0 ]]; then
        echo -e "${YELLOW}⚠️ Tidak ada tag. Gunakan default branch.${NC}"
    else
        for i in "${!tag_list[@]}"; do
            echo "$((i+1))) ${tag_list[$i]}"
        done
        read -p "🔖 Pilih tag [1-${#tag_list[@]}], Enter untuk skip: " tag_index
        if [[ -n "$tag_index" ]]; then
            checked_out_tag="${tag_list[$((tag_index-1))]}"
            git checkout "$checked_out_tag"
        fi
    fi
}

add_feeds() {
    echo -e "${YELLOW}🔍 Menyesuaikan feed luci berdasarkan tag...${NC}"

    luci_branch="master"
    if [[ "$checked_out_tag" =~ ^v([0-9]+)\.([0-9]+) ]]; then
        major="${BASH_REMATCH[1]}"
        minor="${BASH_REMATCH[2]}"
        luci_branch="openwrt-${major}.${minor}"
    fi

    echo -e "${GREEN}✅ Feed luci akan menggunakan branch: ${luci_branch}${NC}"

    # Tulis ulang feed.conf.default
    echo "src-git luci https://github.com/openwrt/luci;$luci_branch" > feeds.conf.default

    echo -e "${BLUE}Pilih feed tambahan:${NC}"
    printf "1) ❌  %-25s\n" "Tanpa feed tambahan"
    printf "2) 🧪  %-25s\n" "Custom Feed (BootLoopLover)"
    printf "3) 🐘  %-25s\n" "PHP7 Feed (Legacy)"
    printf "4) 🌐  %-25s\n" "Custom + PHP7"
    echo "========================================================="
    read -p "🔹 Pilih [1-4]: " feed_choice

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
        1) ;; # Tidak menambah feed
        *) echo -e "${RED}❌ Pilihan tidak valid.${NC}"; exit 1 ;;
    esac

    echo -e "${GREEN}🔄 Update feeds...${NC}"
    ./scripts/feeds update -a && ./scripts/feeds install -a
}



# === Preset Config Menu ===
use_preset_menu() {
    echo -e "${BLUE}Gunakan preset config?${NC}"
    echo "1) ✅ Ya (rekomendasi)"
    echo "2) ❌ Tidak (manual tick config)"
    read -p "🔹 Pilihan [1-2]: " preset_answer

    if [[ "$preset_answer" == "1" ]]; then
        if [[ ! -d "../preset" ]]; then
            echo -e "${YELLOW}📦 Meng-clone preset config...${NC}"
            if ! git clone "https://github.com/BootLoopLover/preset.git" "../preset"; then
                echo -e "${RED}❌ Gagal clone preset. Lanjutkan manual config.${NC}"
                make menuconfig
                return
            fi
        fi

        echo -e "${BLUE}📂 Preset tersedia:${NC}"
        mapfile -t folders < <(find ../preset -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
        
        if [[ ${#folders[@]} -eq 0 ]]; then
            echo -e "${RED}❌ Tidak ada folder preset ditemukan. Lanjut manual config.${NC}"
            make menuconfig
            return
        fi

        for i in "${!folders[@]}"; do
            echo "$((i+1))) ${folders[$i]}"
        done

        read -p "🔹 Pilih folder preset [1-${#folders[@]}]: " preset_choice
        selected_folder="../preset/${folders[$((preset_choice-1))]}"
        cp -rf "$selected_folder"/* ./
        [[ -f "$selected_folder/config-nss" ]] && cp "$selected_folder/config-nss" .config
    else
        [[ ! -f .config ]] && make menuconfig
    fi
}


# === Build Menu & Execution ===
build_action_menu() {
    echo -e "\n📋 ${BLUE}Menu Build:${NC}"
    printf "1) 🔄  %-30s\n" "Update feeds saja"
    printf "2) 🧪  %-30s\n" "Update feeds + menuconfig"
    printf "3) 🛠️  %-30s\n" "Jalankan menuconfig saja"
    printf "4) 🏗️  %-30s\n" "Mulai proses build"
    printf "5) 🔙  %-30s\n" "Kembali ke menu sebelumnya"
    printf "6) ❌  %-30s\n" "Keluar dari skrip"
    echo "========================================================="
    read -p "🔹 Pilihan [1-6]: " choice
    case "$choice" in
        1) ./scripts/feeds update -a && ./scripts/feeds install -a ;;
        2) ./scripts/feeds update -a && ./scripts/feeds install -a; make menuconfig ;;
        3) make menuconfig ;;
        4) return 0 ;;
        5) cd ..; return 1 ;;
        6) echo -e "${GREEN}🙋 Keluar.${NC}"; exit 0 ;;
        *) echo -e "${RED}⚠️ Input tidak valid.${NC}" ;;
    esac
    return 1
}

start_build() {
    echo -e "${GREEN}🚀 Mulai build dengan 20 threads...${NC}"
    start_time=$(date +%s)
    if make -j20 > build.log 2>&1; then
        echo -e "${GREEN}✅ Build berhasil!${NC}"
    else
        echo -e "${RED}⚠️ Build gagal, coba ulang dengan output verbose...${NC}"
        make -j20 V=s | tee build-error.log
    fi
    end_time=$(date +%s)
    elapsed=$((end_time - start_time))
    echo -e "${BLUE}⏱️ Build selesai dalam $((elapsed / 60)) menit $((elapsed % 60)) detik.${NC}"
    command -v notify-send &>/dev/null && notify-send "OpenWrt Build" "✅ Build selesai di folder: $(pwd)"
}

# === Fresh Build ===
fresh_build() {
    echo -e "\n📁 Pilih folder build baru:"
    printf "1) %-20s 3) %s\n" "openwrt"       "openwrt-ipq (qosmio)"
    printf "2) %-20s 4) %s\n" "immortalwrt"   "lede (coolsnowwolf)"

    while true; do
        read -p "🔹 Pilihan [1-5]: " choice
        case "$choice" in
            1) folder_name="openwrt";       git_url="https://github.com/openwrt/openwrt";;
            2) folder_name="immortalwrt";   git_url="https://github.com/immortalwrt/immortalwrt";;
            3) folder_name="openwrt-ipq";   git_url="https://github.com/qosmio/openwrt-ipq";;
            4) folder_name="lede";   git_url="https://github.com/coolsnowwolf/lede.git";;
            *) echo -e "${RED}❌ Pilihan tidak valid.${NC}"; continue;;
        esac
        break
    done

    echo -e "\n📂 Folder dipilih : ${YELLOW}$folder_name${NC}"
    mkdir -p "$folder_name" && cd "$folder_name" || { echo -e "${RED}❌ Gagal masuk folder.${NC}"; exit 1; }

    echo -e "🔗 Clone dari: ${GREEN}$git_url${NC}"
    git clone "$git_url" . || { echo -e "${RED}❌ Gagal clone repo.${NC}"; exit 1; }

    [[ "$git_url" == *"coolsnowwolf/lede"* ]] && apply_lede_patch

    echo -e "${GREEN}🔄 Menjalankan update & install feeds awal...${NC}"
    ./scripts/feeds update -a && ./scripts/feeds install -a

    checkout_tag
    add_feeds
    use_preset_menu

    if ! grep -q "^CONFIG_TARGET" .config 2>/dev/null; then
        echo -e "${RED}❌ Target board belum diatur. Jalankan menuconfig dulu.${NC}"
        make menuconfig
    fi

    start_build
}


rebuild_mode() {
    while true; do
        show_banner
        echo -e "📂 ${BLUE}Pilih folder build yang sudah ada:${NC}"
        mapfile -t folders < <(find . -maxdepth 1 -type d ! -name ".")
        for i in "${!folders[@]}"; do
            echo "$((i+1))) ${folders[$i]##*/}"
        done
        echo "0) ❌ Exit"
        read -p "🔹 Pilihan [0-${#folders[@]}]: " choice
        if [[ "$choice" == 0 ]]; then
            echo -e "${GREEN}🙋 Keluar.${NC}"; exit 0
        elif [[ "$choice" =~ ^[0-9]+$ && "$choice" -le "${#folders[@]}" ]]; then
            folder="${folders[$((choice-1))]}"
            cd "$folder" || continue
            while ! build_action_menu; do :; done
            start_build
            break
        else
            echo -e "${RED}⚠️ Pilihan tidak valid.${NC}"
        fi
    done
}

main_menu() {
    show_banner
    echo "1️⃣ Fresh build (baru)"
    echo "2️⃣ Rebuild dari folder lama"
    echo "3️⃣ Keluar"
    echo "========================================================="
    read -p "🔹 Pilih opsi [1-3]: " main_choice
    case "$main_choice" in
        1) fresh_build ;;
        2) rebuild_mode ;;
        3) echo -e "${GREEN}🙋 Keluar.${NC}"; exit 0 ;;
        *) echo -e "${RED}⚠️ Pilihan tidak valid.${NC}"; exit 1 ;;
    esac
}

# === Mulai ===
main_menu
