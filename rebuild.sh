#!/bin/bash
#--------------------------------------------------------
# 🚀 OpenWrt Rebuild Script - Technical Style with Folder Selection
# 👨‍💻 Author: Pakalolo Waraso
#--------------------------------------------------------

BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

while true; do
    # === Tampilan Awal ===
    clear
    echo -e "🛠️  ${BLUE}Universal Compile OpenWrt/ImmortalWrt/OpenWrt-IPQ${NC}"
    echo "--------------------------------------------------------"
    echo -e "✨ ${BLUE}Firmware Modifications Project${NC}"
    echo -e "🌐 ${BLUE}GitHub   : https://github.com/BootLoopLover${NC}"
    echo -e "💬 ${BLUE}Telegram : t.me/PakaloloWaras0${NC}"
    echo "--------------------------------------------------------"

    # === Pilih Folder Build ===
    echo -e "📂 ${BLUE}Select build folder to continue:${NC}"
    echo "1️⃣  openwrt"
    echo "2️⃣  immortalwrt"
    echo "3️⃣  openwrt-ipq"
    echo "❌  4) Exit"
    read -p "📌 Choice [1/2/3/4]: " distro_choice

    case "$distro_choice" in
        1) build_folder="openwrt" ;;
        2) build_folder="immortalwrt" ;;
        3) build_folder="openwrt-ipq" ;;
        4) echo -e "${GREEN}👋 Exiting...${NC}"; exit 0 ;;
        *) echo -e "${RED}⚠️  Invalid choice. Try again.${NC}"; continue ;;
    esac

    if [[ ! -d "$build_folder" ]]; then
        echo -e "${RED}❗ Error: Folder '${build_folder}' not found. Try again.${NC}"
        continue
    fi

    cd "$build_folder" || { echo -e "${RED}❌ Failed to access folder. Try again.${NC}"; continue; }

    # === Menu Aksi ===
    while true; do
        echo -e "\n📋 ${BLUE}Select action:${NC}"
        echo "--------------------------------------------------------"
        echo -e "💡 ${YELLOW}Note: Make sure your feeds are ready before building...${NC}"
        echo -e "📦 ${BLUE}Add your feeds now if needed...${NC}"
        echo "--------------------------------------------------------"
        echo "🔄  1) Update feeds only"
        echo "🔧  2) Update feeds and run menuconfig"
        echo "🛠️   3) Run menuconfig only"
        echo "🏗️   4) Proceed to build"
        echo "🔙  5) Back to folder selection"
        echo "❌  6) Exit script"
        read -p "📌 Choice [1-6]: " choice

        case "$choice" in
            1)
                echo -e "${BLUE}🔄 Updating feeds only...${NC}"
                ./scripts/feeds update -a
                ./scripts/feeds install -a
                continue
                ;;
            2)
                echo -e "${BLUE}🔄 Updating feeds...${NC}"
                ./scripts/feeds update -a
                ./scripts/feeds install -a
                echo -e "${BLUE}🛠️  Launching menuconfig...${NC}"
                make menuconfig
                break
                ;;
            3)
                echo -e "${BLUE}🛠️  Launching menuconfig only...${NC}"
                make menuconfig
                break
                ;;
            4)
                echo -e "${GREEN}🏗️  Proceeding to build...${NC}"
                break
                ;;
            5)
                cd ..
                continue 2
                ;;
            6)
                echo -e "${GREEN}👋 Exiting without building.${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}⚠️  Invalid input. Please enter a number between 1 and 6.${NC}"
                ;;
        esac
    done

    # === Konfirmasi Build ===
    while true; do
        echo -e "\n🧩 ${BLUE}Proceed to build now?${NC}"
        echo "--------------------------------------------------------"
        echo "✅  1) Yes, start build"
        echo "❌  2) No, exit"
        echo "🔙  3) Back to action menu"
        read -p "📌 Choice [1/2/3]: " build_confirm

        case "$build_confirm" in
            1)
                echo -e "${BLUE}🏗️  Starting build process...${NC}"
                start_time=$(date +%s)

                if make -j$(nproc); then
                    echo -e "${GREEN}🎉 Build completed successfully!${NC}"
                else
                    echo -e "${RED}⚠️  Build failed. Retrying with verbose output...${NC}"
                    make -j1 V=s
                    echo -e "${RED}🚨 Build finished with errors.${NC}"
                fi

                end_time=$(date +%s)
                elapsed=$((end_time - start_time))
                hours=$((elapsed / 3600))
                minutes=$(((elapsed % 3600) / 60))

                echo -e "${BLUE}⏱️  Total build duration: ${hours} hour(s) and ${minutes} minute(s).${NC}"
                exit 0
                ;;
            2)
                echo -e "${GREEN}🚪 Build canceled by user.${NC}"
                exit 0
                ;;
            3)
                break
                ;;
            *)
                echo -e "${RED}⚠️  Invalid input. Please enter 1, 2, or 3.${NC}"
                ;;
        esac
    done
done
