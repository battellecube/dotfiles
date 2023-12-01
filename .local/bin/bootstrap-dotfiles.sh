#!/usr/bin/env bash


echo "Let's get you setup!"

curl -sSL -o /tmp/install-tools.sh https://raw.githubusercontent.com/battellecube/dotfiles/quick-start/.local/bin/install-tools.sh
bash /tmp/install-tools.sh

configure-dotfiles

echo "All done!!"
