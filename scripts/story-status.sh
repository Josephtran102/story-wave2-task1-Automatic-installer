#!/bin/bash

# Color variables
RED='\033[0;31m'
BLUE='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

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

# Function to check node status
check_node_status() {
    clear
    print_color "blue" "Checking Node Status..."
    echo "Current node status:"
    curl localhost:26657/status | jq
    read -n 1 -s -r -p "Press any key to continue"
}

# Function to check block sync
check_block_sync() {
    clear
    print_color "blue" "Checking Block Sync Status..."
    print_color "yellow" "Press Ctrl+C to stop and return to menu."
    
    trap 'return' INT
    while true; do
        local_height=$(curl -s localhost:26657/status | jq -r '.result.sync_info.latest_block_height');
        network_height=$(curl -s https://rpc-story.josephtran.xyz/status | jq -r '.result.sync_info.latest_block_height');
        blocks_left=$((network_height - local_height));
        echo -e "\033[1;38mYour node height:\033[0m \033[1;34m$local_height\033[0m | \033[1;35mNetwork height:\033[0m \033[1;36m$network_height\033[0m | \033[1;29mBlocks left:\033[0m \033[1;31m$blocks_left\033[0m";
        sleep 5;
    done
}

# Function to check story-geth logs
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

# Function to display menu
display_menu() {
    clear
    local options=("Check Node Status" "Check Block Sync" "Check Story-Geth Logs" "Check Story Logs" "Back to Main Menu")
    local current=$1

    print_color "blue" "=== Story Node Status and Log Checker ==="
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

# Function to handle menu selection
menu() {
    local current=0
    local options=("Check Node Status" "Check Block Sync" "Check Story-Geth Logs" "Check Story Logs" "Back to Main Menu")

    while true; do
        display_menu $current

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
        4) 
           # Set environment variable to signal return to main menu
           export RETURN_TO_MAIN_MENU=1
           return
           ;;
    esac
}

# Main function
main() {
    while true; do
        menu
        if [[ $RETURN_TO_MAIN_MENU -eq 1 ]]; then
            unset RETURN_TO_MAIN_MENU
            break
        fi
    done
}

# Run the main function
main
