#!/bin/bash
#--------------------------------------------------------
# OpenWrt Rebuild Script - Technical Style with Folder Selection
# Author: Pakalolo Waraso
#--------------------------------------------------------

BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

while true; do
    # === Tampilan Awal ===
    clear
    echo -e "\033[1;34mUniversal Compile Openwrt/Immortalwrt/Openwrt-ipq\033[0m"
    echo "--------------------------------------------------------"
    echo -e "\033[1;34mFirmware Modifications Project\033[0m"
    echo -e "\033[1;34mGithub : https://github.com/BootLoopLover\033[0m"
    echo -e "\033[1;34mTelegram : t.me/PakaloloWaras0\033[0m"

    # --- Pilih Folder Build Berdasarkan Distro ---
    echo -e "${BLUE}Select build folder to continue:${NC}"
    echo "--------------------------------------------------------"
    echo "1) openwrt"
    echo "2) immortalwrt"
    echo "3) openwrt-ipq"
    echo "4) Exit"
    read -p "Choice [1/2/3/4]: " distro_choice

    case "$distro_choice" in
        1) build_folder="openwrt" ;;
        2) build_folder="immortalwrt" ;;
        3) build_folder="openwrt-ipq" ;;
        4) exit 0 ;;
        *) echo -e "${RED}Invalid choice. Try again.${NC}"; continue ;;
    esac

    if [[ ! -d "$build_folder" ]]; then
        echo -e "${RED}Error: Folder '${build_folder}' not found. Try again.${NC}"
        continue
    fi

    cd "$build_folder" || { echo -e "${RED}Failed to access folder. Try again.${NC}"; continue; }

    # --- Menu Pilihan Aksi ---
    while true; do
        echo -e "\n${BLUE}Select action:${NC}"
        echo "--------------------------------------------------------"
        echo -e "${BLUE}Note : Make sure your feeds are ready before proceeding...${NC}"
        echo -e "\033[1;34mAdd your feeds now...\033[0m"
        echo "--------------------------------------------------------"
        echo "1) Update feeds and run menuconfig"
        echo "2) Skip feeds update and menuconfig, proceed to build"
        echo "3) Exit script"
        echo "4) Run menuconfig only (no feeds update)"
        echo "5) Back to folder selection"
        read -p "Choice [1/2/3/4/5]: " choice

        case "$choice" in
            1)
                echo -e "${BLUE}Updating feeds...${NC}"
                ./scripts/feeds update -a
                ./scripts/feeds install -a
                echo -e "${BLUE}Launching menuconfig...${NC}"
                make menuconfig
                break
                ;;
            2)
                echo -e "${GREEN}Skipping feeds update and menuconfig.${NC}"
                break
                ;;
            3)
                echo -e "${GREEN}Exiting without building.${NC}"
                exit 0
                ;;
            4)
                echo -e "${BLUE}Launching menuconfig only...${NC}"
                make menuconfig
                break
                ;;
            5)
                cd ..
                continue 2
                ;;
            *)
                echo -e "${RED}Invalid input. Please enter 1-5.${NC}"
                ;;
        esac
    done

    # --- Konfirmasi Build ---
    while true; do
        echo "--------------------------------------------------------"
        echo -e "\n${BLUE}Proceed to build now?${NC}"
        echo "--------------------------------------------------------"
        echo "1) Yes, start build"
        echo "2) No, exit"
        echo "3) Back to action menu"
        read -p "Choice [1/2/3]: " build_confirm

        case "$build_confirm" in
            1)
                echo -e "${BLUE}Starting build process...${NC}"
                start_time=$(date +%s)

                if make -j$(nproc); then
                    echo -e "${GREEN}Build completed successfully.${NC}"
                else
                    echo -e "${RED}Build failed. Retrying with verbose output...${NC}"
                    make -j1 V=s
                    echo -e "${RED}Build finished with errors.${NC}"
                fi

                end_time=$(date +%s)
                elapsed=$((end_time - start_time))
                hours=$((elapsed / 3600))
                minutes=$(((elapsed % 3600) / 60))

                echo -e "${BLUE}Total build duration: ${hours} hour(s) and ${minutes} minute(s).${NC}"
                exit 0
                ;;
            2)
                echo -e "${GREEN}Build canceled by user.${NC}"
                exit 0
                ;;
            3)
                break
                ;;
            *)
                echo -e "${RED}Invalid input. Please enter 1, 2, or 3.${NC}"
                ;;
        esac
    done
done
