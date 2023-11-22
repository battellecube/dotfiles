#!/bin/bash

set -e

install-common-packages()
{
	sudo apt update
	sudo apt dist-upgrade -y
	sudo apt install -y powerline vim-nox build-essential gnupg curl tmux git{,-lfs} silversearcher-ag etckeeper xdg-utils wslu software-properties-common python3-pip
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
	sudo apt-get update && sudo apt-get install terraform -y
}

install-github-cli()
{
	type -p curl >/dev/null || install-common-packages
	curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
	sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
	sudo apt update && sudo apt install gh -y
	if ! gh auth status >/dev/null 2>&1; then
		echo "Need to login into gh to continue"
		gh auth login
	fi
}

install-cube-cli()
{
	type -p gh >/dev/null || install-github-cli
	type -p gpg >/dev/null || install-common-packages
	gh repo clone battellecube/cube-env
	cd  cube-env
	git checkout deb_repo
	cat KEY.gpg | gpg --dearmor | sudo dd of=/usr/share/keyrings/cubeenvcli-archive-keyring.gpg
	sudo chmod go+r /usr/share/keyrings/cubeenvcli-archive-keyring.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/cubeenvcli-archive-keyring.gpg] https://battellecube.github.io/cube-env ./" | sudo tee /etc/apt/sources.list.d/cube-env.list > /dev/null
	echo "deb-src [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/cubeenvcli-archive-keyring.gpg] https://battellecube.github.io/cube-env ./" | sudo tee -a /etc/apt/sources.list.d/cube-env.list > /dev/null
	sudo apt update
	sudo apt install -y cube-env
	sudo apt build-dep -y cube-env
}

install-common-packages
install-github-cli
install-terraform-cli
install-azure-cli
install-cube-cli
