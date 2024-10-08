#!/bin/bash

# Color variables
RED='\033[0;31m'
BLUE='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color


# INSTALL_SCRIPT_PATH="https://story.josephtran.co/scripts/story-node-installer.sh"
# MANAGE_SCRIPT_PATH="https://story.josephtran.co/scripts/story-manage-node.sh"
# REMOVE_SCRIPT_PATH="https://story.josephtran.co/scripts/story-remove-node.sh"
# UPGRADE_SCRIPT_PATH="https://story.josephtran.co/scripts/story-node-upgrader.sh"
# DOWNLOAD_SCRIPT_PATH="https://story.josephtran.co/scripts/story-download-snapshot.sh"


# Default snapshot URLs
DEFAULT_STORY_SNAPSHOT="https://story.josephtran.co/Story_snapshot.lz4"
DEFAULT_GETH_SNAPSHOT="https://story.josephtran.co/Geth_snapshot.lz4"

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

# Function to install Story node
install_story_node() {
    clear
    print_color "blue" "Starting Story node installation..."
    if source <(curl -s https://story.josephtran.co/scripts/story-node-installer.sh); then
        print_color "blue" "✅ Story node installation completed"
    else
        print_color "red" "❌ Failed to install Story node"
    fi
    read -n 1 -s -r -p "Press any key to continue"
}

# Function to manage node
manage_node() {
    clear
    print_color "blue" "Starting node management..."
    if source <(curl -s https://story.josephtran.co/scripts/story-manage-node.sh); then
        print_color "blue" "✅ Node management completed"
    else
        print_color "red" "❌ Failed to execute node management"
    fi
    # read -n 1 -s -r -p "Press any key to continue"
}

# Function to remove node
remove_node() {
    clear
    print_color "yellow" "Starting node removal process..."
    if source <(curl -s https://story.josephtran.co/scripts/story-remove-node.sh); then
        print_color "blue" "✅ Node removal process completed"
    else
        print_color "red" "❌ Failed to execute node removal"
    fi
    read -n 1 -s -r -p "Press any key to continue"
}

# Function to check node status
check_node_status() {
    clear
    print_color "blue" "Checking Node Status..."
    CONFIG_FILE="$HOME/.story/story/config/config.toml"
    if [ -f "$CONFIG_FILE" ]; then
        PORT=$(sed -n '/^\[rpc\]/,/^\[/p' "$CONFIG_FILE" | grep 'laddr = "tcp://' | grep -oP ':\K\d+')
        if [ -z "$PORT" ]; then
            echo "Could not find RPC port in config file."
            return
        fi
    else
        echo "Configuration file not found!"
        return
    fi
    echo "Current node status:"
    curl -s "localhost:$PORT/status" | jq
    read -n 1 -s -r -p "Press any key to continue"
}


# Function to check block sync
check_block_sync() {
    clear
    print_color "blue" "Checking Block Sync Status..."
    print_color "yellow" "Press Ctrl+C to stop and return to menu."

    CONFIG_FILE="$HOME/.story/story/config/config.toml"

    if [ -f "$CONFIG_FILE" ]; then
        PORT=$(sed -n '/^\[rpc\]/,/^\[/p' "$CONFIG_FILE" | grep 'laddr = "tcp://' | grep -oP ':\K\d+')
        if [ -z "$PORT" ]; then
            echo "Could not find RPC port in config file."
            return
        fi
    else
        echo "Configuration file not found!"
        return
    fi

    trap 'return' INT
    while true; do
        local_height=$(curl -s "localhost:$PORT/status" | jq -r '.result.sync_info.latest_block_height')
        network_height=$(curl -s https://rpc-story.josephtran.xyz/status | jq -r '.result.sync_info.latest_block_height')
        
        if [ -z "$local_height" ] || [ -z "$network_height" ]; then
            echo "Error: Unable to fetch block heights. Please check your node and network connection."
            sleep 5
            continue
        fi
        
        blocks_left=$((network_height - local_height))
        
        echo -e "\033[1;38mYour node height:\033[0m \033[1;34m$local_height\033[0m | \033[1;35mNetwork height:\033[0m \033[1;36m$network_height\033[0m | \033[1;29mBlocks left:\033[0m \033[1;31m$blocks_left\033[0m"
        sleep 5
    done
}

# Function to check Geth logs
check_geth_logs() {
    clear
    print_color "blue" "Checking Story-Geth Logs..."
    print_color "yellow" "Press Ctrl+C to stop and return to menu."
    sudo journalctl -u story-geth -f -o cat
}

# Function to check story logs
check_story_logs() {
    clear
    print_color "blue" "Checking Story Logs..."
    print_color "yellow" "Press Ctrl+C to stop and return to menu."
    sudo journalctl -u story -f -o cat
}

# Function to download snapshot
download_snapshot() {
    clear
    print_color "blue" "Starting snapshot download process..."
    if source <(curl -s https://story.josephtran.co/scripts/story-download-snapshot.sh); then
        print_color "blue" "✅ Snapshot download completed"
    else
        print_color "red" "❌ Failed to execute download snapshot"
    fi
    read -n 1 -s -r -p "Press any key to continue"
}


# Function to upgrade node
upgrade_node() {
    clear
    print_color "blue" "Starting node upgrade process..."
    if source <(curl -s https://story.josephtran.co/scripts/story-node-upgrader.sh); then
        print_color "blue" "✅ Node upgrade process completed"
    else
        print_color "red" "❌ Failed to execute upgrade node"
    fi
    read -n 1 -s -r -p "Press any key to continue"
}

# Function to display main menu
display_main_menu() {
    clear
    local options=(
        "Install Story node | One-liner" 
        "Manage node | Version, Port, Backup keys, Stop/Start" 
        "Check node | status, block sync, logs" 
        "Upgrade node"  
        "Download latest snapshot" 
        "Backup & Remove node" 
        "Exit"
    )
    local current=$1

    print_color "blue" "=== Story Node Manager | J•Node | www.josephtran.xyz ==="
    echo "Use arrow keys to navigate, Enter to select, or type the number of your choice."
    echo ""

    for i in "${!options[@]}"; do
        if [ "$i" -eq "$current" ]; then
            echo -e "${BLUE}> $((i+1)). ${options[$i]}${NC}"
        else
            echo "  $((i+1)). ${options[$i]}"
        fi
    done
}


# Function to display status and logs menu
display_status_menu() {
    local options=("Check Node Status" "Check Block Sync" "Check Geth Logs" "Check Story Logs" "Back to Main Menu")
    local current=$1

    print_color "blue" "=== Story Node Status and Log Checker | J•Node | www.josephtran.xyz ==="
    echo "Use arrow keys to navigate, Enter to select, or type the number of your choice."
    echo ""

    for i in "${!options[@]}"; do
        if [ "$i" -eq "$current" ]; then
            echo -e "${BLUE}> $((i+1)). ${options[$i]}${NC}"
        else
            echo "  $((i+1)). ${options[$i]}"
        fi
    done
}

# Function to handle status and logs menu selection
status_menu() {
    local current=0
    local options=("Check Node Status" "Check Block Sync" "Check Geth Logs" "Check Story Logs" "Back to Main Menu")

    while true; do
        clear
        display_status_menu $current

        # Read a single character
        read -s -n 1 key

        # Handle arrow keys, numbers, and enter
        if [[ $key == $'\e' ]]; then
            read -s -n 2 key
            if [[ $key == '[A' ]]; then  # Up arrow
                ((current--))
                [ "$current" -lt 0 ] && current=$((${#options[@]}-1))
            elif [[ $key == '[B' ]]; then  # Down arrow
                ((current++))
                [ "$current" -ge "${#options[@]}" ] && current=0
            fi
        elif [[ $key =~ ^[1-9]$ ]]; then  # Number keys
            if [ "$key" -le "${#options[@]}" ]; then
                current=$((key-1))
                break
            fi
        elif [[ $key == '' ]]; then  # Enter key
            break
        fi
    done

    case $current in
        0) check_node_status ;;
        1) check_block_sync ;;
        2) check_geth_logs ;;
        3) check_story_logs ;;
        4) return ;;
    esac

    status_menu  # Return to status menu after function completes
}

# Function to display main menu
display_main_menu() {
    clear
    local options=(
        "Install Story node | One-liner" 
        "Manage node | Version, Port, Backup keys, Stop/Start" 
        "Check node | status, block sync, logs" 
        "Upgrade node"  
        "Download latest snapshot" 
        "Backup & Remove node" 
        "Exit"
    )
    local current=$1

    print_color "blue" "=== Story Node Manager | J•Node | www.josephtran.xyz ==="
    echo "Use arrow keys to navigate, Enter to select, or type the number of your choice."
    echo ""

    for i in "${!options[@]}"; do
        if [ "$i" -eq "$current" ]; then
            echo -e "${BLUE}> $((i+1)). ${options[$i]}${NC}"
        else
            echo "  $((i+1)). ${options[$i]}"
        fi
    done
}

# Function to handle main menu selection
main_menu() {
    local current=0
    local options=(
        "Install Story node | One-liner" 
        "Manage node | Version, Port, Backup keys, Stop/Start" 
        "Check node | status, block sync, logs" 
        "Upgrade node"  
        "Download latest snapshot" 
        "Backup & Remove node" 
        "Exit"
    )

    while true; do
        display_main_menu $current

        # Read a single character
        read -s -n 1 key

        # Handle arrow keys, numbers, and enter
        if [[ $key == $'\e' ]]; then
            read -s -n 2 key
            if [[ $key == '[A' ]]; then  # Up arrow
                ((current--))
                [ "$current" -lt 0 ] && current=$((${#options[@]}-1))
            elif [[ $key == '[B' ]]; then  # Down arrow
                ((current++))
                [ "$current" -ge "${#options[@]}" ] && current=0
            fi
        elif [[ $key =~ ^[1-7]$ ]]; then  # Number keys
            current=$((key-1))
        elif [[ $key == '' ]]; then  # Enter key
            case $current in
                0) install_story_node ;;
                1) manage_node ;;
                2) status_menu ;;
                3) upgrade_node ;;  
                4) download_snapshot ;;
                5) remove_node ;;
                6) return 1 ;;  # Signal to exit
            esac
            # Clear input buffer
            while read -t 0.1 -n 1; do : ; done
        fi
    done
}

# Main function
main() {
    while true; do
        if main_menu; then
            continue
        else
            break
        fi
    done
    print_color "blue" "Exiting Story Node Manager | www.josephtran.xyz | Goodbye!"
}

# Run the main function
main
