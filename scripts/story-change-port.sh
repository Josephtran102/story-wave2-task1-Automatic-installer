#!/bin/bash

CONFIG_FILE="$HOME/.story/story/config/config.toml"


if [ ! -f "$CONFIG_FILE" ]; then
    echo "Configuration file not found!"
    exit 1
fi


read -p "Enter the new base port number (e.g., 22): " NEW_BASE_PORT


cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"


sed -i -E "
    s/(tcp:\/\/127\.0\.0\.1:)([0-9]{2})([0-9]{3})/\1$NEW_BASE_PORT\3/g;
    s/(tcp:\/\/0\.0\.0\.0:)([0-9]{2})([0-9]{3})/\1$NEW_BASE_PORT\3/g;
    s/(laddr = \"tcp:\/\/127\.0\.0\.1:)([0-9]{2})([0-9]{3})/\1$NEW_BASE_PORT\3/g;
    s/(laddr = \"tcp:\/\/0\.0\.0\.0:)([0-9]{2})([0-9]{3})/\1$NEW_BASE_PORT\3/g
" "$CONFIG_FILE"


echo "Changed lines:"
diff -u "${CONFIG_FILE}.bak" "$CONFIG_FILE" | grep -E '^\+' | sed 's/^\+//'


echo "Ports have been updated in $CONFIG_FILE."
