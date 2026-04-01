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
scriptused=0
sudo_vault="54sdig4tb7p4cd2upehoa4qooe"
sudo_item="uenihzentw3pm2vbzu4n73jjny"
sudo_field="password"

# install chezmoi

chezmoi_v=$(lynx -dump https://github.com/twpayne/chezmoi/releases/latest \
| grep -E "^v[0-9.]+$" | head -n 1 | cut -c 2-)


################################################################################
#
# Line wrap ruler
#
#   5   10   15   20   25   30   35   40   45   50   55   60   65   70   75   80
#
################################################################################

