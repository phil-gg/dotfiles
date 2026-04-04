#!/bin/bash

################################################################################
# Choose whether to pre-authenticate 1password and/or sudo.
#
# This copy has no go templating & chezmoi drops this in ~/.config/scripts
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
op_token_in_ram_path="/dev/shm/op_session_token_${USER}"
tokenloaded="0"
scriptused="0"
sudo_vault="54sdig4tb7p4cd2upehoa4qooe"
sudo_item="uenihzentw3pm2vbzu4n73jjny"
sudo_field="password"

# Now running `${local_filename}`

echo -e "\n${bluebold}Now running ‘${local_filename}’${normal}"

# Manage 1password-cli signin

echo -e "\n${cyanbold}Manage 1password-cli authentication (op signin)${normal}"

# Check if the token file exists
if [[ -f "${op_token_in_ram_path}" ]]
    
    # Branch where prior op session token exists
    then
    # Read the token and export it for this script's session
    OP_SESSION_my=$(cat "${op_token_in_ram_path}")
    export OP_SESSION_my
    tokenloaded="1"
    echo -e "${greenbold}> 1password-cli session token loaded${normal}"
    
    # Branch where *NO* prior op session token exists
    else
    echo -e "${redbold}> No 1password-cli session token loaded${normal}"
    
    # Close whether token file exists condition
fi

# Now check whether you have a valid 1password-cli session
if op whoami &> /dev/null
    
    # Branch where token is valid
    then
    echo -e "${greenbold}> op signin complete${normal}"
    
    # Branch where token not valid or non existent
    else
    # Message only if token existed but not valid
    if (( tokenloaded == 1 )); then
        echo -e "${redbold}> 1password-cli token expired${normal}"
    fi
    # Choice: message
    read -r -p "> Authenticate 1password-cli (op signin) now? (Y/n) " response
    # Convert the string to lowercase
    response="${response,,}"
    
    # Choice: check for 'y', 'yes', or an empty string (-z)
    if [[ "${response}" == "y" || "${response}" == "yes" || -z "${response}" ]]
        
        # Branch where you want to create a new valid token for 1password-cli
        then
        (( scriptused += 1 ))
        echo -e "\n${cyanbold}Checking whether account registered in 1password-cli${normal}"
        
        # Check whether account(s) registered in 1password-cli
        if ! op account list 2> /dev/null | grep -q "1password.com"
            
            # Branch for account registration
            then
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
            echo -e ""
            
            # Branch for op signin only
            else
            echo -e "${greenbold}> Account(s) registered in 1password-cli${normal}"
            
        # Close check whether account(s) registered in 1password-cli
        fi
        
        # Everyone now has account(s) registered - here they are
        echo -e "$ op account list\n"
        op account list
        # Now generate a new session token
        echo -e "\n${cyanbold}Now sign into 1password-cli${normal}"
        echo -e "$ op signin --raw > ${op_token_in_ram_path}\n"
        raw_token=$(op signin --raw)
        
        # Check for errors in generating new session token
        if [[ -n "${raw_token}" ]]
            
            # Branch where new token was successfully generated
            then
            # Write to RAM and instantly lock down file permissions
            touch "${op_token_in_ram_path}"
            chmod 600 "${op_token_in_ram_path}"
            echo "${raw_token}" > "${op_token_in_ram_path}"
            OP_SESSION_my="${raw_token}"
            export OP_SESSION_my
            echo -e "${greenbold}> op session token successfully stored in memory${normal}"
            
            # Branch to handle token generation errors
            else
            echo -e "${redbold}> op signin failed${normal}"
            exit 111
            
        # Close check for errors in generating new session token
        fi
        
        # Branch where you declined to create a new valid token for 1password-cli
        else
        echo -e "${redbold}> You chose no. All secrets injection from 1password will be skipped for this chezmoi run${normal}"
        
    # Close [Y/n] choice whether to sign into 1password
    fi
# Close check whether you have a valid 1password-cli session
fi

# Manage sudo authentication

echo -e "\n${cyanbold}Manage sudo authentication${normal}"

# Check whether sudo is already warm
if sudo -n true 2>/dev/null
    
    # Branch where sudo is already warm
    then
    echo -e "${greenbold}> sudo is pre-authenticated${normal}"
    
    # Branch with no pre-existing sudo rights
    else
    echo -e "${redbold}> no sudo privileges granted (yet)${normal}"
    # Choice: message
    read -r -p "> Run ‘sudo -v’ now? (Y/n) " response
    # Convert the string to lowercase
    response="${response,,}"
    
    # Choice: check for 'y', 'yes', or an empty string (-z)
    if [[ "${response}" == "y" || "${response}" == "yes" || -z "${response}" ]]
        
        # Branch where you want to warm sudo
        then
        (( scriptused += 2 ))
        
        # Check if 1password-cli signed in (for autofill vs interactive sudo)
        if op whoami &> /dev/null
            
            # Branch where 1password-cli credentials can warm sudo
            then
            echo -e "> Authenticating sudo with 1password…"
            # Don't show real credential commands in dummy command
            echo -e "$ op read \"op://\${vault}/\${item}/\${field}\" | sudo -S -v &> /dev/null"
            
            # Check for failure with 1password-cli authenticating sudo
            if op read "op://${sudo_vault}/${sudo_item}/${sudo_field}" | sudo -S -v &> /dev/null; then
                echo -e "${greenbold}> Sudo successfully authenticated${normal}"
                else
                echo -e "${redbold}> 1Password authentication failed. Falling back to interactive prompt:${normal}"
                echo -e "$ sudo -v"
                if sudo -v; then
                    echo -e "${greenbold}> Sudo successfully authenticated${normal}"
                else
                    echo -e "${redbold}> Sudo authentication failed${normal}"
                    exit 112
                fi
            # Close check for failure with 1password authenticating sudo
            fi
            
            # Branch where no 1password-cli credentials are available
            else
            echo -e "$ sudo -v"
            if sudo -v; then
                echo -e "${greenbold}> Sudo successfully authenticated${normal}"
            else
                echo -e "${redbold}> Sudo authentication failed${normal}"
                exit 113
            fi
        # Close check if 1password-cli signed in (for autofill vs interactive sudo)
        fi
        
        # Branch where you declined to warm sudo
        else
        echo -e "${redbold}> You chose no. Certain scripts will still prompt you for sudo later…${normal}"
        
    # Close [Y/n] choice whether to warm sudo
    fi
# Close check whether sudo is already warm
fi

# Display runtime & conditionally log this latest `Config` operation

echo -e "\n${bluebold}${local_filename} run at${normal}"
echo -e "> ${runtime}"
if (( scriptused > 0 )); then
mkdir -p "${HOME}/git/${github_username}/${github_project}" && \
echo -e "FILE: ${local_filename} | EXEC-TIME: ${runtime}" \
>> "${HOME}/git/${github_username}/${github_project}/config-runs.log"
echo -e "> ${scriptused} - run logged\n"
else
echo -e "> ${scriptused} - run not logged\n"
# Close conditional logging
fi

################################################################################
#
# Line wrap ruler
#
#   5   10   15   20   25   30   35   40   45   50   55   60   65   70   75   80
#
################################################################################

