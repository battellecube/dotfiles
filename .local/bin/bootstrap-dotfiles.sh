#!/usr/bin/env bash


echo "Let's get you setup!"

curl -sSL -o /tmp/install-tools.sh https://raw.githubusercontent.com/battellecube/dotfiles/quick-start/.local/bin/install-tools.sh
bash /tmp/install-tools.sh

USER_NAME="$(git config --global user.name)"
USER_EMAIL="$(git config --global user.email)"

if [[ ! "$USER_NAME" ]]; then
	read -p "What is your full name? " USER_NAME
fi
echo "Hello, $USER_NAME"


