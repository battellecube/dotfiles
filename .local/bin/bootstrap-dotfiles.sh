#!/usr/bin/env bash


echo "Let's get you setup!"

# export BRANCH to test a branch other than main
# if BRANCH is zero-length, use main
if [ -z $BRANCH ]; then
	BRANCH='main'
else
	echo "Using the $BRANCH branch"
fi

curl -sSL -o /tmp/install-tools.sh https://raw.githubusercontent.com/battellecube/dotfiles/$BRANCH/.local/bin/install-tools.sh
bash /tmp/install-tools.sh

curl -sSL -o /tmp/configure-dotfiles.sh https://raw.githubusercontent.com/battellecube/dotfiles/$BRANCH/.local/bin/configure-dotfiles.sh
bash /tmp/configure-dotfiles.sh

# Hook user dotfiles, if exist
username=$(gh auth status | grep -oP 'github.com account \K[^ ]+')
gh repo view $username/dotfiles --json name &>/dev/null && {
	echo Hooking dotfiles for $username
}

echo "All done!!"
