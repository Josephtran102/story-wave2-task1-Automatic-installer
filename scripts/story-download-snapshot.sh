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

# Function to check command status
check_status() {
    if [ $? -eq 0 ]; then
        print_color "blue" "✅ $1"
    else
        print_color "red" "❌ $1"
        return 1
    fi
}

# Function to check versions
check_versions() {
    clear
    print_color "blue" "=== Check Versions | J•Node | www.josephtran.xyz ==="
    
    print_color "yellow" "Loading bash profile..."
    source ~/.bash_profile
    check_status "Bash profile loaded"

    echo "Story version:"
    if story version; then
        check_status "Story version checked"
    else
        print_color "red" "Failed to check Story version"
    fi

    echo ""
    echo "Story-Geth version:"
    if story-geth version; then
        check_status "Story-Geth version checked"
    else
        print_color "red" "Failed to check Story-Geth version"
    fi

    read -n 1 -s -r -p "Press any key to continue"
}

# Function to change port for node
change_port() {
    CONFIG_FILE="$HOME/.story/story/config/config.toml"

    if [ ! -f "$CONFIG_FILE" ]; then
        print_color "red" "Configuration file not found!"
        return 1
    fi

    read -p "Enter the new base port number (e.g., 22): " NEW_BASE_PORT

    cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"

    sed -i -E "
        s/(tcp:\/\/127\.0\.0\.1:)([0-9]{2})([0-9]{3})/\1$NEW_BASE_PORT\3/g;
        s/(tcp:\/\/0\.0\.0\.0:)([0-9]{2})([0-9]{3})/\1$NEW_BASE_PORT\3/g;
        s/(laddr = \"tcp:\/\/127\.0\.0\.1:)([0-9]{2})([0-9]{3})/\1$NEW_BASE_PORT\3/g;
        s/(laddr = \"tcp:\/\/0\.0\.0\.0:)([0-9]{2})([0-9]{3})/\1$NEW_BASE_PORT\3/g
    " "$CONFIG_FILE"

    print_color "yellow" "Changed lines:"
    diff -u "${CONFIG_FILE}.bak" "$CONFIG_FILE" | grep -E '^\+' | sed 's/^\+//'

    print_color "blue" "Ports have been updated in $CONFIG_FILE."
    read -n 1 -s -r -p "Press any key to continue"
}

# Function to export keys
export_keys() {
    clear
    print_color "blue" "=== Export Keys | J•Node | www.josephtran.xyz ==="
    
    print_color "yellow" "Loading bash profile..."
    source $HOME/.bash_profile
    check_status "Bash profile loaded"

    print_color "yellow" "Exporting keys..."
    story validator export --export-evm-key
    check_status "Keys exported"

    print_color "blue" "Keys have been exported. Please check the output above for the location of the exported keys."
    read -n 1 -s -r -p "Press any key to continue"
}


# Function to manage node (stop/start) and check versions
manage_node() {
    local options=(
        "Check Versions"
        "Change port for node"
        "Export Keys"
        "Stop Story" 
        "Stop Story-Geth" 
        "Stop Both" 
        "Start Story" 
        "Start Story-Geth" 
        "Start Both" 
        "Back to main menu"
    )
    local current=0

    while true; do
        clear
        print_color "blue" "=== Manage Node | J•Node | www.josephtran.xyz ==="
        echo "Use arrow keys to navigate, Enter to select, or type the number of your choice."
        echo ""

        for i in "${!options[@]}"; do
            if [ "$i" -eq "$current" ]; then
                echo -e "${BLUE}> $((i+1)). ${options[$i]}${NC}"
            else
                echo "  $((i+1)). ${options[$i]}"
            fi
        done

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
        0) check_versions ;;
        1) change_port ;;
        2) export_keys ;;
        3) 
            sudo systemctl stop story
            check_status "Story stopped"
            ;;
        4) 
            sudo systemctl stop story-geth
            check_status "Story-Geth stopped"
            ;;
        5) 
            sudo systemctl stop story
            sudo systemctl stop story-geth
            check_status "Both services stopped"
            ;;
        6) 
            sudo systemctl start story
            check_status "Story started"
            ;;
        7) 
            sudo systemctl start story-geth
            check_status "Story-Geth started"
            ;;
        8) 
            sudo systemctl start story
            sudo systemctl start story-geth
            check_status "Both services started"
            ;;
        9) return ;;
        *) print_color "red" "Invalid choice" ;;
    esac
    [[ $current != 9 ]] && read -n 1 -s -r -p "Press any key to continue"
}

# Main execution
while true; do
    manage_node
    # If manage_node returns (user chose "Back to main menu"), break the loop
    [[ $? -eq 0 ]] && break
done

print_color "blue" "Exiting Story Node Manager."
