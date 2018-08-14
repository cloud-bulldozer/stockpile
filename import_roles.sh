#!/bin/bash

if [[ $# -ne 4 ]]; then
	echo "Usage: $0 <github_token> <github_user> <github_repo> <github_branch> [galaxy_server_url]"
	exit 1
fi

github_token=$1
github_user=$2
github_repo=$3
github_branch=$4
galaxy_server_url=$5

# ensure that dependencies are installed
which ansible &>/dev/null
if [[ $? != 0 ]]; then
	echo "Looks like ansible is not installed on the system, installing it"
	yum install ansible -y
fi
which mazer &>/dev/null
if [[ $? != 0 ]]; then
	easy_install pip
	pip install mazer
fi

# use defaults if galaxy_server_url and branch are not defined
if [[ -z "$galaxy_server" ]]; then
	galaxy_server_url="https://galaxy.ansible.com"
fi

# login into ansible-galaxy using the github api token
ansible-galaxy login --github-token=$github_token

# import roles
ansible-galaxy import -s $galaxy_server_url --branch $github_branch $github_user $github_repo
