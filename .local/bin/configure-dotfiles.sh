#!/usr/bin/env bash

set -e

# TODO How the username and email is determined and verified will change when
# we move to Github EMU, as it's tied to our enterprise user directory. For now
# we'll use `git` to bootstrap the current this info for now.
GH_USER_NAME=$(git config --global user.name)

# Show current username and prompt for a new one
echo "Current Github username: $GH_USER_NAME"
read -p "Enter new Github username (or press enter to keep current): " NEW_USER_NAME

# Update the username only if a new one is provided
if [ -n "$NEW_USER_NAME" ]; then
	GH_USER_NAME="$NEW_USER_NAME"
fi

# Set the new or existing username globally
git config --global user.name "$GH_USER_NAME"

# Get the current global Git email
GH_USER_EMAIL=$(git config --global user.email)

# Show current email and prompt for a new one
echo "Current Github email: $GH_USER_EMAIL"
read -p "Enter new Github email (or press enter to keep current): " NEW_USER_EMAIL

# Update the email only if a new one is provided
if [ -n "$NEW_USER_EMAIL" ]; then
	GH_USER_EMAIL="$NEW_USER_EMAIL"
fi

# Set the new or existing email globally
git config --global user.email "$GH_USER_EMAIL"

# Fetch the current authentication status and store it in a variable
output=$(gh auth status)

# Initialize a flag variable to track if required scopes are present
scopes_exist=false

# Check if both required scopes 'delete_repo' and 'write:gpg_key' are present in the output
if echo "$output" | grep -q "delete_repo" && echo "$output" | grep -q "write:gpg_key"; then
	scopes_exist=true
fi

# If the required scopes are not present, refresh authentication with the necessary scopes
if [ "$scopes_exist" = false ]; then
	gh auth refresh --scopes delete_repo,write:gpg_key
fi

# Fetch GPG keys associated with a specific email domain from GitHub and store them in an array
GPG_KEYS=($(gh gpg-key list | awk '/battelle.org/{print $2}'))

# Initialize a flag to track if a key is found
key_found=false

# Iterate over the keys to check if they are present in the local GPG keyring
for k in "${GPG_KEYS[@]}"; do
	if gpg --list-keys "$k" &> /dev/null; then
		GH_SIGNING_KEY=$k
		key_found=true
		break
	fi
done

# If no key is found, create a new GPG key
if [ "$key_found" = "false" ]; then
	echo "Creating a new GPG key"

	# Create a temporary directory for GPG configuration and key generation logs
	TEMP_DIR=$(mktemp -dq)
	CONFIG_FILE="$TEMP_DIR/key-config"

	# Generate a GPG key configuration file
	cat > "$CONFIG_FILE" <<-EOF
		%echo Generating a basic OpenPGP key
		Key-Type: RSA
		Key-Length: 4096
		Subkey-Type: RSA
		Subkey-Length: 4096
		Name-Real: $GH_USER_NAME
		Name-Email: $GH_USER_EMAIL
		Expire-Date: 0
		%no-protection
		%commit
		%echo Done
	EOF

	# Generate a GPG key using the configuration file
	gpg --batch --generate-key "$CONFIG_FILE" &> $TEMP_DIR/gpg.log

	# Extract the generated key ID from the log
	GH_SIGNING_KEY=$(grep 'key .* marked as ultimately trusted' $TEMP_DIR/gpg.log | awk '{print $3}')

	# Export the public key to a file
	gpg --export --armor "$GH_SIGNING_KEY" > "$TEMP_DIR/pub_key.asc"

	echo "Uploading new key to Github"
	# Upload the new GPG key to GitHub
	gh gpg-key add "$TEMP_DIR/pub_key.asc"
fi

cat <<END

---------------------------
Git
  username: $GH_USER_NAME
  email:    $GH_USER_EMAIL
  key:      $GH_SIGNING_KEY
---------------------------

END
