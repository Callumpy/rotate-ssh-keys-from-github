#!/bin/bash

# The location of the authorized_keys file
AUTHORIZED_KEYS="$HOME/.ssh/authorized_keys"

# The Github usernames for the users whose public keys you want to add
USERNAMES=("username1" "username2" "username3")

# Retrieve each user's public keys from the github.com/<USERNAME>.keys URL and append them to the authorized_keys file
KEYS=""
for USERNAME in "${USERNAMES[@]}"
do
    USER_KEYS=$(curl -s "https://github.com/$USERNAME.keys")
    if [ -n "$USER_KEYS" ]; then
        KEYS="$KEYS"$'\n'"$USER_KEYS"
    else
        echo "Unable to retrieve public keys for $USERNAME"
        exit 1
    fi
done

# Remove any keys that are no longer in the Github profiles
for KEY in $(cut -f 2 -d ' ' "$AUTHORIZED_KEYS" | sort -u); do
    if ! grep -q "$KEY" <<< "$KEYS"; then
        awk -v key="$KEY" '$0 !~ key' "$AUTHORIZED_KEYS" > "$AUTHORIZED_KEYS.tmp" && mv "$AUTHORIZED_KEYS.tmp" "$AUTHORIZED_KEYS"
        echo "Removed key $KEY from $AUTHORIZED_KEYS"
    fi
done

# Append any new keys to the authorized_keys file
while read -r KEY; do
    # Check if the key already exists in the authorized_keys file
    if grep -q "$KEY" "$AUTHORIZED_KEYS"; then
        echo "Public key for $(echo "$KEY" | cut -d ' ' -f 3) already exists in $AUTHORIZED_KEYS"
    else
        echo "$KEY" >> "$AUTHORIZED_KEYS"
        echo "Public key for $(echo "$KEY" | cut -d ' ' -f 3) has been added to $AUTHORIZED_KEYS"
    fi
done <<< "$KEYS"
