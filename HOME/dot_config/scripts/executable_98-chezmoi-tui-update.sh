#!/bin/bash
echo -ne $'\033]0;Chezmoi update\007'
chezmoi update
read -srp $'\033[1;35mEnd of script. Press RETURN to close window.\033[0m\n'
