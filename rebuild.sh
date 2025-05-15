#!/bin/bash
#--------------------------------------------------------
# OpenWrt Rebuild Script
# Folder Selection, Custom Feeds Injection,
# Feeds Update/Menuconfig Option, Build Timing
#--------------------------------------------------------

BLUE='\033[1;34m'
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m'

# --- Select Build Folder ---
echo -e "${BLUE}Select target build folder:${NC}"
echo "1) openwrt"
echo "2) openwrt-ipq"
echo "3) immortalwrt"
read -p "Choice [1/2/3]: " folder_choice

case "$folder_choice" in
    1) build_folder="openwrt" ;;
    2) build_folder="openwrt-ipq" ;;
    3) build_folder="immortalwrt" ;;
    *) echo -e "${RED}Invalid selection. Exiting.${NC}"; exit 1 ;;
esac

if [[ ! -d "$build_folder" ]]; then
    echo -e "${RED}Directory '${build_folder}' not found. Terminating.${NC}"
    exit 1
fi

cd "$build_folder" || { echo -e "${RED}Failed to access directory. Exiting.${NC}"; exit 1; }

# --- Custom Feeds Input ---
echo -e "${BLUE}Enter custom 'src-git' feed lines to append to feeds.conf.default."
echo "Input each line and press Enter."
echo "Press Enter on empty line to finish."
echo -e "${BLUE}Input lines:${NC}"

while true; do
    read -r line
    [[ -z "$line" ]] && break
    echo "$line" >> feeds.conf.default
done

echo -e "${GREEN}Custom feeds appended successfully.${NC}"

# --- Feeds Update and Menuconfig Option ---
echo -e "\n${BLUE}Select next action:${NC}"
echo "1) Update feeds and execute 'make menuconfig'"
echo "2) Skip feeds update and proceed directly to build"
read -p "Choice [1/2]: " action_choice

case "$action_choice" in
    1)
        echo -e "${BLUE}Updating feeds...${NC}"
        ./scripts/feeds update -a
        ./scripts/feeds install -a
        echo -e "${BLUE}Launching 'make menuconfig'...${NC}"
        make menuconfig
        ;;
    2)
        echo -e "${GREEN}Skipping feeds update and menuconfig.${NC}"
        ;;
    *)
        echo -e "${RED}Invalid input. Exiting.${NC}"
        exit 1
        ;;
esac

# --- Build Confirmation ---
echo -e "\n${BLUE}Proceed with build?${NC}"
echo "1) Yes"
echo "2) No (exit)"
read -p "Choice [1/2]: " build_confirm

if [[ "$build_confirm" != "1" ]]; then
    echo -e "${GREEN}Build cancelled by user.${NC}"
    exit 0
fi

# --- Build Process with Timing ---
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
seconds=$((elapsed % 60))

echo -e "${BLUE}Total build duration: ${hours}h ${minutes}m ${seconds}s.${NC}"
