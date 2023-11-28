#!/usr/bin/env bash


echo "Let's get you setup!"

curl -sSL -o /tmp/install-tools.sh https://raw.githubusercontent.com/battellecube/dotfiles/quick-start/.local/bin/install-tools.sh
bash /tmp/install-tools.sh

USER_NAME="$(git config --global user.name)"
[[ "$USER_NAME" ]] || {
	read -p "What is your full name? " USER_NAME
	git config --global user.name "$USER_NAME"
}

USER_EMAIL="$(git config --global user.email)"
[[ "$USER_EMAIL" ]] || {
	read -p "What is your battelle.org email? " USER_EMAIL
	git config --global user.email "$USER_EMAIL"
}

echo "All done!!"

