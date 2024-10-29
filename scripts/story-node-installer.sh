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

# Install dependencies
install_dependencies() {
    print_color "blue" "Installing dependencies..."
    sudo apt update
    sudo apt-get update
    sudo apt install curl git make jq build-essential gcc unzip wget lz4 aria2 -y
    check_status "Dependencies installed"
}

# Download and install Story-Geth
install_story_geth() {
    print_color "blue" "Downloading and installing Story-Geth..."
    wget https://github.com/piplabs/story-geth/releases/download/v0.10.0/geth-linux-amd64
    [ ! -d "$HOME/go/bin" ] && mkdir -p $HOME/go/bin
    if ! grep -q "$HOME/go/bin" $HOME/.bash_profile; then
        echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
    fi
    chmod +x geth-linux-amd64
    mv $HOME/geth-linux-amd64 $HOME/go/bin/story-geth
    source $HOME/.bash_profile
    story-geth version
    check_status "Story-Geth installed"
}

# Download and install Story binary
install_story_binary() {
    print_color "blue" "Downloading and installing Story binary..."
    wget https://github.com/piplabs/story/releases/download/v0.12.0/story-linux-amd64
    chmod +x story-linux-amd64
    sudo cp $HOME/story-linux-amd64 $HOME/go/bin/story
    source $HOME/.bash_profile
    story version
    check_status "Story binary installed"
}

# Initialize Iliad node
init_iliad_node() {
    local moniker=$1
    print_color "blue" "Initializing Iliad node..."
    story init --network odyssey --moniker "$moniker"
    check_status "Odyssey node initialized"
}

# Create service files
create_service_files() {
    print_color "blue" "Creating service files..."
    # Create story-geth service file
    sudo tee /etc/systemd/system/story-geth.service > /dev/null <<EOF
[Unit]
Description=Story Geth Client
After=network.target

[Service]
User=root
ExecStart=/root/go/bin/story-geth --odyssey --syncmode full
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

    # Create story service file
    sudo tee /etc/systemd/system/story.service > /dev/null <<EOF
[Unit]
Description=Story Consensus Client
After=network.target

[Service]
User=root
ExecStart=/root/go/bin/story run
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

    check_status "Service files created"
}

# Start services
start_services() {
    print_color "blue" "Starting services..."
    sudo systemctl daemon-reload
    sudo systemctl start story-geth
    sudo systemctl enable story-geth
    sudo systemctl start story
    sudo systemctl enable story
    check_status "Services started"
}

# Install Story node
install_story_node() {
    read -p "Enter your moniker name: " moniker
    install_dependencies
    install_story_geth
    install_story_binary
    init_iliad_node "$moniker"
    create_service_files
    start_services
    print_color "blue" "Story node installation completed!"
}

# Main execution
install_story_node
