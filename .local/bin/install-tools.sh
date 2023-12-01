#!/bin/bash

set -e

install-common-packages()
{
	sudo apt update
	sudo apt dist-upgrade -y
	sudo apt install -y vim-nox build-essential gnupg curl git{,-lfs} etckeeper xdg-utils wslu software-properties-common
	git lfs install
}

install-azure-cli() 
{
	type -p curl >/dev/null || install-common-packages
	curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
	az cloud set --name AzureUSGovernment
	az config set extension.use_dynamic_install=yes_without_prompt
}

install-terraform-cli()
{
	type -p curl gpg >/dev/null || install-common-packages
	curl -sSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo dd of=/usr/share/keyrings/hashicorp-archive-keyring.gpg
	sudo chmod go+r /usr/share/keyrings/hashicorp-archive-keyring.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/terraform-cli.list > /dev/null
	sudo apt update && sudo apt install terraform -y
}

install-github-cli()
{
	type -p curl >/dev/null || install-common-packages
	curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
	sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
	sudo apt update && sudo apt install gh -y
}

install-cube-cli()
{
	type -p gh >/dev/null || install-github-cli
	type -p gpg >/dev/null || install-common-packages
	type -p git >/dev/null || install-common-packages
	local REPO=$(mktemp -d)
	gh repo clone battellecube/cube-env $REPO
	cd  $REPO
	git checkout deb_repo
	cat KEY.gpg | gpg --dearmor | sudo dd of=/usr/share/keyrings/cubeenvcli-archive-keyring.gpg
	sudo chmod go+r /usr/share/keyrings/cubeenvcli-archive-keyring.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/cubeenvcli-archive-keyring.gpg] https://battellecube.github.io/cube-env ./" | sudo tee /etc/apt/sources.list.d/cube-env.list > /dev/null
	echo "deb-src [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/cubeenvcli-archive-keyring.gpg] https://battellecube.github.io/cube-env ./" | sudo tee -a /etc/apt/sources.list.d/cube-env.list > /dev/null
	sudo apt update
	sudo apt install -y cube-env
	sudo apt build-dep -y cube-env
}

# remove lingering lists in case script was run previously and failed
#sudo rm /etc/apt/source.list.d/{github-cli.list,terraform-cli.list,cube-env.list}

[[ "$(id -u)" == "0" ]] || {
	echo "Please login for sudo access"
	sudo true
}

echo -n "Installing base packages..."
install-common-packages &>/dev/null
echo "done."
type -p gh >/dev/null || {
	echo -n "Installing Github CLI..."
	install-github-cli &>/dev/null
	echo "done."
}

gh auth status &>/dev/null || {
	echo "Need to login into gh to continue"
	gh auth refresh --scopes delete_repo,write:gpg_key
}

type -p terraform &>/dev/null || {
	echo -n "Installing Terraform CLI..."
	install-terraform-cli &>/dev/null
	echo "done."
}

type -p az &>/dev/null || {
	echo -n "Install Azure CLI..."
	install-azure-cli &>/dev/null
	echo "done."
}

type -p cube &>/dev/null || {
	echo -n "Installing CUBE CLI..."
	install-cube-cli &>/dev/null
	echo "done."
}

echo -e "\nFinished!"
