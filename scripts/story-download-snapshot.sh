#!/bin/bash

# Color variables
RED='\033[0;31m'
BLUE='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Default snapshot URLs
DEFAULT_STORY_SNAPSHOT="https://josephtran.co/Story_snapshot.lz4"
DEFAULT_GETH_SNAPSHOT="https://josephtran.co/Geth_snapshot.lz4"

# Function to print colored output
print_color() {
    case $1 in
        "blue") COLOR=$BLUE ;;
        "red") COLOR=$RED ;;
        "yellow") COLOR=$YELLOW ;;
        *) COLOR=$NC ;;
    esac
    echo -e "${COLOR}$2${NC}"
}

# Function to check command status
check_status() {
    if [ $? -eq 0 ]; then
        print_color "blue" "✅ $1"
    else
        print_color "red" "❌ $1"
        return 1
    fi
}

# Function to install tools
install_tools() {
    print_color "yellow" "Installing required tools: wget lz4 aria2 pv"
    sudo apt-get update
    sudo apt-get install wget lz4 aria2 pv -y
    check_status "Tools installation"
    read -n 1 -s -r -p "Press any key to continue"
}

# Function to choose download source
choose_download_source() {
    local current=0
    local options=("Download from JosephTran (recommended)" "Input custom snapshot URLs" "Back")

    while true; do
        clear
        print_color "blue" "Choose Download Source:"
        echo "Use arrow keys to navigate, Enter to select, or type the number of your choice."
        echo ""

        for i in "${!options[@]}"; do
            if [ "$i" -eq "$current" ]; then
                echo -e "${BLUE}> $((i+1)). ${options[$i]}${NC}"
            else
                echo "  $((i+1)). ${options[$i]}"
            fi
        done

        read -s -n 1 key

        if [[ $key == $'\e' ]]; then
            read -s -n 2 key
            if [[ $key == '[A' ]]; then  # Up arrow
                ((current--))
                [ "$current" -lt 0 ] && current=$((${#options[@]}-1))
            elif [[ $key == '[B' ]]; then  # Down arrow
                ((current++))
                [ "$current" -ge "${#options[@]}" ] && current=0
            fi
        elif [[ $key =~ ^[1-3]$ ]]; then  # Number keys
            current=$((key-1))
            break
        elif [[ $key == '' ]]; then  # Enter key
            break
        fi
    done

    case $current in
        0)
            story_snapshot_url=$DEFAULT_STORY_SNAPSHOT
            geth_snapshot_url=$DEFAULT_GETH_SNAPSHOT
            print_color "blue" "Using default snapshots from JosephTran"
            download_snapshots
            ;;
        1)
            print_color "yellow" "Please enter the URLs for custom snapshots:"
            read -p "Enter Story snapshot URL: " story_snapshot_url
            read -p "Enter Geth snapshot URL: " geth_snapshot_url
            download_snapshots
            ;;
        2)
            return  # Back to previous menu
            ;;
    esac
}

# Function to download snapshots
download_snapshots() {
    # Stop node
    print_color "yellow" "Stopping Story node..."
    sudo systemctl stop story
    sudo systemctl stop story-geth
    check_status "Node stopped"

    # Confirm with user
    print_color "yellow" "You have chosen to download snapshots from:"
    print_color "blue" "Story snapshot: $story_snapshot_url"
    print_color "blue" "Geth snapshot: $geth_snapshot_url"
    read -p "Do you want to proceed? (y/n): " confirm
    if [[ $confirm != "y" && $confirm != "Y" ]]; then
        print_color "yellow" "Snapshot download cancelled by user."
        return
    fi

    # Download snapshots
    print_color "yellow" "Downloading Story snapshot..."
    cd $HOME
    rm -f Story_snapshot.lz4
    wget --show-progress $story_snapshot_url -O Story_snapshot.lz4
    check_status "Story snapshot download"

    print_color "yellow" "Downloading Geth snapshot..."
    rm -f Geth_snapshot.lz4
    wget --show-progress $geth_snapshot_url -O Geth_snapshot.lz4
    check_status "Geth snapshot download"

    # Backup priv_validator_state.json
    print_color "yellow" "Backing up priv_validator_state.json..."
    cp ~/.story/story/data/priv_validator_state.json ~/.story/priv_validator_state.json.backup
    check_status "Backup creation"

    # Remove old data
    print_color "yellow" "Removing old data..."
    rm -rf ~/.story/story/data
    rm -rf ~/.story/geth/iliad/geth/chaindata
    check_status "Old data removal"

    # Decompress snapshots
    print_color "yellow" "Decompressing Story snapshot..."
    sudo mkdir -p /root/.story/story/data
    lz4 -d -c Story_snapshot.lz4 | pv | sudo tar xv -C ~/.story/story/ > /dev/null
    check_status "Story snapshot decompression"

    print_color "yellow" "Decompressing Geth snapshot..."
    sudo mkdir -p /root/.story/geth/iliad/geth/chaindata
    lz4 -d -c Geth_snapshot.lz4 | pv | sudo tar xv -C ~/.story/geth/iliad/geth/ > /dev/null
    check_status "Geth snapshot decompression"

    # Restore priv_validator_state.json
    print_color "yellow" "Restoring priv_validator_state.json..."
    cp ~/.story/priv_validator_state.json.backup ~/.story/story/data/priv_validator_state.json
    check_status "Restore priv_validator_state.json"

    # Restart node
    print_color "yellow" "Restarting Story node..."
    sudo systemctl start story
    sudo systemctl start story-geth
    check_status "Node restart"

    print_color "blue" "Snapshot download and installation process completed!"
    read -n 1 -s -r -p "Press any key to continue"
}

# Function to display snapshot submenu
display_snapshot_submenu() {
    local current=0
    local options=("Install tools: wget lz4 aria2 pv" "Choose download source" "Back to main menu")

    while true; do
        clear
        print_color "blue" "Download Latest Snapshot Submenu:"
        echo "Use arrow keys to navigate, Enter to select, or type the number of your choice."
        echo ""

        for i in "${!options[@]}"; do
            if [ "$i" -eq "$current" ]; then
                echo -e "${BLUE}> $((i+1)). ${options[$i]}${NC}"
            else
                echo "  $((i+1)). ${options[$i]}"
            fi
        done

        read -s -n 1 key

        if [[ $key == $'\e' ]]; then
            read -s -n 2 key
            if [[ $key == '[A' ]]; then  # Up arrow
                ((current--))
                [ "$current" -lt 0 ] && current=$((${#options[@]}-1))
            elif [[ $key == '[B' ]]; then  # Down arrow
                ((current++))
                [ "$current" -ge "${#options[@]}" ] && current=0
            fi
        elif [[ $key =~ ^[1-3]$ ]]; then  # Number keys
            current=$((key-1))
            break
        elif [[ $key == '' ]]; then  # Enter key
            break
        fi
    done

    case $current in
        0) install_tools ;;
        1) choose_download_source ;;
        2) return ;;
    esac

    display_snapshot_submenu
}

# Execute the snapshot submenu
display_snapshot_submenu
