#!/bin/bash
# shellcheck disable=SC2034

################################################################################
# Choose whether to pre-authenticate 1password and/or sudo.
#
# Go template functionality in chezmoi blanks out whole script if either:
# - Scenario 1: 1password-cli is not installed
# - Scenario 2: Both 1password-cli is signed in and sudo is warm
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
git_filename="run_always_before_01-1password-sudo-choices.sh.tmpl"
local_filename="01-1password-sudo-choices.sh"
runtime=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
normal=$(printf '\033[0m')
redbold=$(printf '\033[91;1m')
greenbold=$(printf '\033[92;1m')
cyanbold=$(printf '\033[96;1m')
bluebold=$(printf '\033[94;1m')
scriptused="0"
sudo_vault="54sdig4tb7p4cd2upehoa4qooe"
sudo_item="uenihzentw3pm2vbzu4n73jjny"
sudo_field="password"

# Now running `${local_filename}`

echo -e "\n${bluebold}Now running ‘${local_filename}’${normal}"

# Check whether signed into 1password-cli
if ! op whoami &> /dev/null; then

echo -e "\n${cyanbold}Do you want to run these chezmoi scripts with secrets from 1password?${normal}"
read -r -p "> Sign into 1password-cli now? (Y/n) " response
# Convert the string to lowercase
response="${response,,}"

# Check for 'y', 'yes', or an empty string (-z)
if [[ "${response}" == "y" || "${response}" == "yes" || -z "${response}" ]]

then
(( scriptused += 1 ))
echo -e "\n${cyanbold}Checking whether account registered in 1password-cli${normal}"

# Check whether account(s) registered in 1password-cli
if ! op account list 2> /dev/null | grep -q "1password.com"; then
echo -e "${redbold}> No accounts registered in 1password-cli${normal}
> sign-in address = my.1password.com
>  email  address = p… .c…@gmail.com
>   For secret key:
>    Open https://my.1password.com/apps
>    …and click ‘Sign in manually’ button
> Next enter master password
> Finally enter TOTP from another 1password instance

$ eval \$(op account add --signin)
"
# shellcheck disable=SC2046
eval $(op account add --signin)

else
echo -e "${greenbold}> Account(s) registered in 1password-cli${normal}"
echo -e "\n$ op account list\n"
op account list
echo -e "\n${cyanbold}Now sign into 1password-cli${normal}"
echo -e "\n$ eval \$(op signin)\n"
# shellcheck disable=SC2046
eval $(op signin)

# Close check whether account(s) registered in 1password-cli
fi

else
echo -e "${redbold}> You chose no. All secrets injection from 1password will be skipped for this chezmoi run.${normal}"

# Close [Y/n] choice whether to sign into 1password
fi
# Close check whether signed into 1password-cli
fi

# Check whether sudo is already warm
if ! sudo -n true 2>/dev/null; then

echo -e "\n${cyanbold}Do you want to run these chezmoi scripts with sudo privileges?${normal}"
read -r -p "> Run ‘sudo -v’ now? (Y/n) " response
# Convert the string to lowercase
response="${response,,}"

# Check for 'y', 'yes', or an empty string (-z)
if [[ "${response}" == "y" || "${response}" == "yes" || -z "${response}" ]]

then
(( scriptused += 2 ))

# Check if 1password-cli signed in (for autofill vs interactive sudo)
if op whoami &> /dev/null; then
echo -e "> Authenticating sudo with 1password…"
# Don't show real credential commands in dummy command
echo -e "$ op read \"op://\${vault}/\${item}/\${field}\" | sudo -S -v &> /dev/null"

# Check for failure with 1password-cli authenticating sudo
if op read "op://${sudo_vault}/${sudo_item}/${sudo_field}" | sudo -S -v &> /dev/null; then
echo -e "${greenbold}> Sudo successfully authenticated.${normal}"
else
echo -e "${redbold}> 1Password authentication failed. Falling back to interactive prompt:${normal}"
echo -e "$ sudo -v"
sudo -v
# Close check for failure with 1password authenticating sudo
fi

else
echo -e "$ sudo -v"
sudo -v
# Close check if 1password-cli signed in (for autofill vs interactive sudo)
fi

else
echo -e "${redbold}> You chose no. Certain scripts will still prompt you for sudo later…${normal}"

# Close [Y/n] choice whether to warm sudo
fi
# Close check whether sudo is already warm
fi

# Log this latest `Config` operation and display runtime

if (( scriptused > 0 )); then
echo -e "\n${bluebold}${local_filename} run at${normal}"
echo -e "> ${runtime}\n"
mkdir -p "${HOME}/git/${github_username}/${github_project}"
echo -e "FILE: ${local_filename} | EXEC-TIME: ${runtime}" \
>> "${HOME}/git/${github_username}/${github_project}/config-runs.log"
# Close conditional logging
fi
