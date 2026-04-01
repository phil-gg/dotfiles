#!/bin/bash

################################################################################
# Bootstrap Debian for configuration with chezmoi.
#
# This script aims to be idempotent; see `#term-Idempotency` definition at:
# https://docs.ansible.com/ansible/latest/reference_appendices/glossary.html
#
# This shell script attempts to comply with:
# https://google.github.io/styleguide/shellguide.html
#
# Should (hopefully, mostly) pass analysis with ShellCheck, too:
# https://www.shellcheck.net
################################################################################

# Set variables

github_username="phil-gg"
github_project="dotfiles"
github_branch="main"
filename="01-bootstrap.sh"
runtime=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
normal=$(printf '\033[0m')
redbold=$(printf '\033[91;1m')
greenbold=$(printf '\033[92;1m')
cyanbold=$(printf '\033[96;1m')
bluebold=$(printf '\033[94;1m')
pkgarch=$(dpkg --print-architecture)

# Now running `${filename}`

echo -e "\n${bluebold}Now running ‘${filename}’${normal}"

# Make folder(s) if they don't exist

if [ ! -d "${HOME}/git/${github_username}/${github_project}/tmp" ]; then
echo -e "\n$ mkdir -p ~/git/${github_username}/${github_project}/tmp"
mkdir -p "${HOME}/git/${github_username}/${github_project}/tmp"
fi

# Navigate to working directory

echo -e "\n$ cd ~/git/${github_username}/${github_project}/tmp"
cd "${HOME}/git/${github_username}/${github_project}/tmp" 2> /dev/null \
|| { echo -e "${redbold}> Failed to change directory, exiting${normal}\n"\
; exit 101; }

# install chezmoi

chezmoi_version=$(lynx -dump -nolink \
https://github.com/twpayne/chezmoi/releases/latest \
| grep -E "^v[0-9.]+$" | head -n 1 | cut -c 2-)



################################################################################
#
# Line wrap ruler
#
#   5   10   15   20   25   30   35   40   45   50   55   60   65   70   75   80
#
################################################################################

