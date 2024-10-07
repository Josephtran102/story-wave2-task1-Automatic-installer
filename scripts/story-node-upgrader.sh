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

# Function to check service status
check_service_status() {
    local service_name=$1
    if systemctl is-active --quiet $service_name; then
        return 0  # Service is running
    else
        return 1  # Service is not running
    fi
}

# Function to stop service safely
stop_service_safely() {
    local service_name=$1
    if check_service_status $service_name; then
        print_color "yellow" "Stopping $service_name..."
        sudo systemctl stop $service_name
        check_status "$service_name stopped"
    else
        print_color "yellow" "$service_name is already stopped."
    fi
}

# Function to install Go
install_go() {
    print_color "blue" "Installing/Updating Go..."
    cd $HOME
    ver="1.22.0"
    wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
    rm "go$ver.linux-amd64.tar.gz"
    echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> ~/.bash_profile
    source $HOME/.bash_profile
    go version
    check_status "Go installation/update"
}

# Function to check and install Go
check_and_install_go() {
    source $HOME/.bash_profile
    if ! command -v go &> /dev/null; then
        print_color "yellow" "Go is not installed. Would you like to install Go? (y/n)"
        read -r install_go_choice
        if [[ $install_go_choice == "y" || $install_go_choice == "Y" ]]; then
            install_go
        else
            print_color "red" "Go is required for the upgrade. Exiting."
            exit 1
        fi
    else
        current_version=$(go version | awk '{print $3}')
        print_color "yellow" "Your current Go version: $current_version. Would you like to update Go? (y/n)"
        read -r update_go
        if [[ $update_go == "y" || $update_go == "Y" ]]; then
            install_go
        fi
    fi
}

# Function to upgrade Story
upgrade_story() {
    local version=$1
    
    check_and_install_go

    stop_service_safely story

    print_color "yellow" "Downloading and building new Story binary..."
    cd $HOME
    rm -rf story
    git clone https://github.com/piplabs/story
    cd $HOME/story
    git checkout $version
    go build -o story ./client
    check_status "Story binary built"

    print_color "yellow" "Installing new Story binary..."
    sudo mv $HOME/story/story $(which story)
    check_status "New Story binary installed"

    print_color "yellow" "Restarting Story node..."
    sudo systemctl daemon-reload
    sudo systemctl start story
    check_status "Story node restarted"

    print_color "blue" "Story upgrade completed. Current version:"
    story version
}

# Function to upgrade Story-Geth
upgrade_story_geth() {
    local version=$1
    
    check_and_install_go

    stop_service_safely story-geth

    print_color "yellow" "Downloading and building new Story-Geth binary..."
    cd $HOME
    rm -rf story-geth
    git clone https://github.com/piplabs/story-geth
    cd $HOME/story-geth
    git checkout $version
    make geth
    check_status "Story-Geth binary built"

    print_color "yellow" "Installing new Story-Geth binary..."
    sudo mv $HOME/story-geth/build/bin/geth $(which story-geth)
    check_status "New Story-Geth binary installed"

    print_color "yellow" "Restarting Story-Geth node..."
    sudo systemctl daemon-reload
    sudo systemctl start story-geth
    check_status "Story-Geth node restarted"

    print_color "blue" "Story-Geth upgrade completed. Current version:"
    story-geth version
}

# Function to check versions
check_versions() {
    clear
    print_color "blue" "=== Check Versions | Story Node Upgrader | J•Node | www.josephtran.xyz ==="
    
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

# Function to display upgrade menu
display_upgrade_menu() {
    local options=("Check Versions" "Upgrade Story" "Upgrade Story-Geth" "Back to Main Menu")
    local current=$1

    print_color "blue" "=== Story Node Upgrader | J•Node | www.josephtran.xyz ==="
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

# Main upgrade function
upgrade_node() {
    local current=0
    local options=("Check Versions" "Upgrade Story" "Upgrade Story-Geth" "Back to Main Menu")

    while true; do
        clear
        display_upgrade_menu $current

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
        elif [[ $key =~ ^[1-4]$ ]]; then  # Number keys
            current=$((key-1))
            break
        elif [[ $key == '' ]]; then  # Enter key
            break
        fi
    done

    case $current in
        0)
            check_versions
            read -n 1 -s -r -p "Press any key to return to the upgrade menu"
            ;;
        1)
            read -p "Enter the Story version to upgrade to (e.g., v0.10.1), or press Enter for latest: " version
            if [ -z "$version" ]; then
                version=$(curl -s https://api.github.com/repos/piplabs/story/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
                print_color "yellow" "Using latest version: $version"
            fi
            upgrade_story $version
            print_color "blue" "Upgrade process completed!"
            read -n 1 -s -r -p "Press any key to return to the upgrade menu"
            ;;
        2)
            read -p "Enter the Story-Geth version to upgrade to (e.g., v0.9.3), or press Enter for latest: " version
            if [ -z "$version" ]; then
                version=$(curl -s https://api.github.com/repos/piplabs/story-geth/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
                print_color "yellow" "Using latest version: $version"
            fi
            upgrade_story_geth $version
            print_color "blue" "Upgrade process completed!"
            read -n 1 -s -r -p "Press any key to return to the upgrade menu"
            ;;
        3)
            print_color "blue" "Returning to main menu..."
            return
            ;;
        *)
            print_color "red" "Invalid choice. Operation cancelled."
            read -n 1 -s -r -p "Press any key to return to the upgrade menu"
            ;;
    esac
}

# Execute the upgrade function
upgrade_node
