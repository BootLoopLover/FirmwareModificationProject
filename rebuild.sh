#!/bin/bash
#--------------------------------------------------------
# OpenWrt Rebuild Script - Technical Style
# Author: Pakalolo Waraso
#--------------------------------------------------------

BLUE='\033[1;34m'
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m'

# --- Validasi Folder Build ---
read -p "$(echo -e ${BLUE}Input existing build folder name (e.g., openwrt, immortalwrt, openwrt-ipq):${NC} )" build_folder

if [[ ! -d "$build_folder" ]]; then
    echo -e "${RED}Error: Folder '${build_folder}' not found. Abort.${NC}"
    exit 1
fi

cd "$build_folder" || { echo -e "${RED}Failed to access folder. Abort.${NC}"; exit 1; }

# --- Menu Pilihan Aksi ---
while true; do
    echo -e "\n${BLUE}Select action:${NC}"
    echo "1) Update feeds and run menuconfig"
    echo "2) Skip feeds update and menuconfig, proceed to build"
    echo "3) Exit script"
    read -p "Choice [1/2/3]: " choice

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
        *)
            echo -e "${RED}Invalid input. Please enter 1, 2, or 3.${NC}"
            ;;
    esac
done

# --- Konfirmasi Build ---
echo -e "\n${BLUE}Proceed to build now?${NC}"
echo "1) Yes, start build"
echo "2) No, exit"
read -p "Choice [1/2]: " build_confirm

if [[ "$build_confirm" == "1" ]]; then
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
else
    echo -e "${GREEN}Build canceled by user.${NC}"
fi
