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

# Function to export keys
export_keys() {
    print_color "blue" "Exporting keys..."
    source $HOME/.bash_profile
    story validator export --export-evm-key
    check_status "Keys exported"
}

# Function to remove node
remove_node() {
    clear
    print_color "blue" "=== Backup & Remove node | J•Node | www.josephtran.xyz ==="
    print_color "yellow" "Warning: This will completely remove the Story node from your system."
    print_color "blue" "Important keys will be automatically saved in $HOME/story-backup:
    - private_key.txt,
    - priv_validator_key.json,
    - node_key.json,
    - priv_validator_state.json)"
    read -p "Are you sure you want to proceed? (y/n): " confirm
    if [[ $confirm == [Yy]* ]]; then
        # Export keys
        export_keys

        # Create backup folder if it doesn't exist
        backup_folder="$HOME/story-backup"
        mkdir -p "$backup_folder"
        
        # Backup important keys
        backup_time=$(date +"%Y%m%d_%H%M%S")
        backup_subfolder="$backup_folder/backup_$backup_time"
        mkdir -p "$backup_subfolder"
        
        files_to_backup=(
            "$HOME/.story/story/config/private_key.txt"
            "$HOME/.story/story/config/priv_validator_key.json"
            "$HOME/.story/story/config/node_key.json"
            "$HOME/.story/story/data/priv_validator_state.json"
        )
        
        for file in "${files_to_backup[@]}"; do
            if [ -f "$file" ]; then
                cp "$file" "$backup_subfolder/"
                print_color "blue" "Backed up: $file"
            else
                print_color "yellow" "File not found, skipping: $file"
            fi
        done
        
        print_color "blue" "Backup completed. Files saved in: $backup_subfolder"
        
        # Proceed with node removal
        print_color "yellow" "Proceeding with node removal..."
        source $HOME/.bash_profile
        sudo systemctl stop story-geth
        sudo systemctl stop story
        sudo systemctl disable story-geth
        sudo systemctl disable story
        sudo rm /etc/systemd/system/story-geth.service
        sudo rm /etc/systemd/system/story.service
        sudo systemctl daemon-reload
        sudo rm -rf $HOME/.story
        sudo rm $HOME/go/bin/story-geth
        sudo rm $HOME/go/bin/story
        check_status "Story node removed"
        
        print_color "blue" "Node removed. Your keys have been backed up to: $backup_subfolder"
    else
        print_color "blue" "Node removal cancelled"
    fi
    read -n 1 -s -r -p "Press any key to continue"
}

# Execute the remove_node function
remove_node
