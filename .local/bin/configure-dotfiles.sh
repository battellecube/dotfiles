#!/usr/bin/env bash

set -e

# BEGIN: Git setup
git config --global user.name || {
	read -p "What is your full name? " USER_NAME
	git config --global user.name "$USER_NAME"
}

git config --global user.email || {
	read -p "What is your battelle.org email? " USER_EMAIL
	git config --global user.email "$USER_EMAIL"
}
# END: Git setup

# need to test for scopes
output=$(gh auth status)
if echo "$output" | grep -q "delete_repo" && echo "$output" | grep -q "write:gpg_key"; then
	scopes_exist='true'
fi
[[ "$scopes_exist" ]] || {
	gh auth refresh --scopes delete_repo,write:gpg_key
}

type -p terraform &>/dev/null || {
	echo -n "Installing Terraform CLI..."
	install-terraform-cli &>/dev/null
	echo "done."
}

# BEGIN: GPG setup
GPG_KEYS=(`gh gpg-key list | awk '/battelle.org/{print $2}'`)

key_found=false

for k in "${GPG_KEYS[@]}"; do
	if gpg --list-keys "$k" &> /dev/null; then
		SIGNING_KEY=$k
		key_found=true
		break
	fi
done

if [ "$key_found" == "false" ]; then
	echo "Creating a new GPG key"
	TEMP_DIR=$(mktemp -dq )
	CONFIG_FILE="$TEMP_DIR/key-config"
	cat > "$CONFIG_FILE" <<-EOF
		%echo Generating a basic OpenPGP key
		Key-Type: RSA
		Key-Length: 4096
		Subkey-Type: RSA
		Subkey-Length: 4096
		Name-Real: $USER_NAME
		Name-Email: $USER_EMAIL
		Expire-Date: 0
		%no-protection
		%commit
		%echo Done
	EOF
	gpg --batch --generate-key "$CONFIG_FILE" &>$TEMP_DIR/gpg.log

	SIGNING_KEY=$(cat $TEMP_DIR/gpg.log | grep 'key .* marked as ultimately trusted' | awk '{print $3}')

	gpg --export --armor $SIGNING_KEY > $TEMP_DIR/pub_key.asc

	echo "Uploading new key to Github"
	gh gpg-key add $TEMP_DIR/pub_key.asc
fi
# END: GPG setup

#LOCAL_KEYS=(`gpg --list-keys --keyid-format long $USER_EMAIL 2>/dev/null | grep 'pub' | awk '{print $2}' | cut -d'/' -f2`)
#MATCHING_KEYS=(`comm -12 <( for k in "${LOCAL_KEYS[@]}"; do echo $k; done | sort) <(for k in "${GPG_KEYS[@]}"; do echo $k; done |sort)`)

cat <<END

---------------------------
Git
  username: $USER_NAME
  email:    $USER_EMAIL
  key:      $SIGNING_KEY
---------------------------

END
