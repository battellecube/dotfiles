#!/usr/bin/env bash


echo "Let's get you setup!"

curl -sSL -o /tmp/install-tools.sh https://raw.githubusercontent.com/battellecube/dotfiles/quick-start/.local/bin/install-tools.sh
bash /tmp/install-tools.sh

curl -sSL -o /tmp/configure-dotfiles.sh https://raw.githubusercontent.com/battellecube/dotfiles/quick-start/.local/bin/configure-dotfiles.sh
bash /tmp/configure-dotfiles.sh

echo "All done!!"
