#!/usr/bin/env bash


#!/bin/bash

set -e

################################################################################
#
#	DECLARE GLOBAL VARIABLES
#
################################################################################

LOGFILE="$(mktemp --quiet)"


################################################################################
#
#	DECLARE FUNCTIONS
#
################################################################################

install-common-packages()
{
	sudo apt update -qq
	sudo apt dist-upgrade -qq -y
	sudo apt install -qq -y vim-nox build-essential gnupg curl git{,-lfs} etckeeper xdg-utils wslu software-properties-common
	git lfs install
}

install-azure-cli() 
{
	type -p curl >>$LOGFILE || install-common-packages
	curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
	az cloud set --name AzureUSGovernment
	az config set extension.use_dynamic_install=yes_without_prompt
}

install-terraform-cli()
{
	type -p curl gpg >>$LOGFILE || install-common-packages
	curl -sSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo dd of=/usr/share/keyrings/hashicorp-archive-keyring.gpg
	sudo chmod go+r /usr/share/keyrings/hashicorp-archive-keyring.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/terraform-cli.list > /dev/null
	sudo apt update -qq && sudo apt install terraform -yqq
}

install-github-cli()
{
	type -p curl >>$LOGFILE || install-common-packages
	curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
	sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
	sudo apt update -qq && sudo apt install gh -yqq
}

install-cube-cli()
{
	type -p gh >>$LOGFILE || install-github-cli
	type -p gpg >>$LOGFILE || install-common-packages
	type -p git >>$LOGFILE || install-common-packages
	local REPO=$(mktemp -d)
	gh repo clone battellecube/cube-env $REPO
	cd  $REPO
	git checkout deb_repo
	cat KEY.gpg | gpg --dearmor | sudo dd of=/usr/share/keyrings/cubeenvcli-archive-keyring.gpg
	sudo chmod go+r /usr/share/keyrings/cubeenvcli-archive-keyring.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/cubeenvcli-archive-keyring.gpg] https://battellecube.github.io/cube-env ./" | sudo tee /etc/apt/sources.list.d/cube-env.list > /dev/null
	echo "deb-src [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/cubeenvcli-archive-keyring.gpg] https://battellecube.github.io/cube-env ./" | sudo tee -a /etc/apt/sources.list.d/cube-env.list > /dev/null
	sudo apt update -qq
	sudo apt install -yqq cube-env
	sudo apt build-dep -yqq cube-env
}


################################################################################
#
#	CONFIGURE ENV TO RUN THIS SCRIPT
#
################################################################################

# Ensure the user is not root and has sudo privileges
if [[ "$(id -u)" == "0" ]]; then
    echo "This script should not be run as root. Please run as a regular user with sudo privileges."
	exit 1
else
    # Check if the user can run commands with sudo
    if sudo -v; then
        echo "Sudo access confirmed."
    else
        echo "You need sudo privileges to run this script."
        exit 1
    fi
fi

# remove lingering lists in case script was run previously and failed
sudo rm -f /etc/apt/sources.list.d/{github-cli.list,terraform-cli.list,cube-env.list}

################################################################################
#
#	INSTALL	PACKAGES
#
################################################################################


install-common-packages

type -p gh &>>$LOGFILE || {
	echo -n "Installing Github CLI..."
	install-github-cli &>>$LOGFILE
	echo "done."
}

type -p terraform &>>$LOGFILE || {
	echo -n "Install Terraform CLI..."
	install-terraform-cli &>>$LOGFILE
	echo "done."
}

type -p az &>>$LOGFILE || {
	echo -n "Install Azure CLI..."
	install-azure-cli &>>$LOGFILE
	echo "done."
}

gh auth status &>>$LOGFILE || {
	echo "Need to login into gh to continue"
	gh auth login
}

type -p cube &>>$LOGFILE || {
	echo -n "Installing CUBE CLI..."
	install-cube-cli #&>>$LOGFILE
	echo "done."
}

############### end install-tools


############### begin configure-dotfiles

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

read -rp "Is the above information correct? [y/N]: " response

# Convert response to lowercase and check
case "${response,,}" in
    y|yes) 
        echo "Proceeding with the operation."
        ;;
    *) 
        echo "Operation aborted."
        exit 1
        ;;
esac


############### end configure-dotfiles





####################
# Hook user dotfiles
####################

# get the github authenticated name
GH_AUTH_NAME=$(gh auth status | grep -oP 'github.com account \K[^ ]+')
# look for a code block in the README.md of the dotfiles repo
BOOTSTRAP=$(gh api repos/$GH_AUTH_NAME/dotfiles/contents/.github/README.md -H "Accept: application/vnd.github.v3.raw" 2>/dev/null| sed -n '/^```/,/^```/p' | sed '/^```/d');
# let's check one more place
[ -z "$BOOTSTRAP" ] && {
	BOOTSTRAP=$(gh api repos/$GH_AUTH_NAME/dotfiles/contents/README.md -H "Accept: application/vnd.github.v3.raw" 2>/dev/null| sed -n '/^```/,/^```/p' | sed '/^```/d');
}
[ -n "$BOOTSTRAP" ] && {
	bash <<-END
	$BOOTSTRAP
	END
}

echo -e "\n\tSee $LOGFILE for detailed output"
echo -e "\nFinished!"
