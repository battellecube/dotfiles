#!/usr/bin/env bash


echo "Let's get you setup!"

# export BRANCH to test a branch other than main
# if BRANCH is zero-length, use main
[ -z $BRANCH ] &&  {
	BRANCH='main'
	echo "Using the $BRANCH branch"
}

curl -sSL -o /tmp/install-tools.sh https://raw.githubusercontent.com/battellecube/dotfiles/$BRANCH/.local/bin/install-tools.sh
bash /tmp/install-tools.sh

curl -sSL -o /tmp/configure-dotfiles.sh https://raw.githubusercontent.com/battellecube/dotfiles/$BRANCH/.local/bin/configure-dotfiles.sh
bash /tmp/configure-dotfiles.sh

echo "All done!!"
