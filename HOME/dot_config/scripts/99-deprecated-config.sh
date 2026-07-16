#!/bin/bash

################################################################################
# Deprecated config removed from other chezmoi scripts.
#
# See `#term-Idempotency` definition at:
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
git_filename="99-deprecated-config.sh"
local_filename="99-deprecated-config.sh"
runtime=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
normal=$(printf '\033[0m')
redbold=$(printf '\033[91;1m')
greenbold=$(printf '\033[92;1m')
cyanbold=$(printf '\033[96;1m')
bluebold=$(printf '\033[94;1m')
pkgarch=$(dpkg --print-architecture)

# Now running `${local_filename}`

echo -e "\n${bluebold}Now running ‘${local_filename}’${normal}"

################################################################################
# Deprecated when chezmoi was added to Sid repo (July 2026)
################################################################################

# Install / Update chezmoi (on any arch)

chezmoi_latestver=$(
curl -ILsS -w "%{url_effective}" -o /dev/null \
"https://github.com/twpayne/chezmoi/releases/latest" \
| sed 's|.*/v\?||'
)
chezmoi_installedver=$(dpkg-query -W -f='${Version}' chezmoi 2> /dev/null)

echo -e "\n${cyanbold}Check chezmoi versions${normal}"
echo -e ">    Latest = ${chezmoi_latestver:-${bluebold}(none)${normal}}"
echo -e "> Installed = ${chezmoi_installedver:-${bluebold}(none)${normal}}"

# Check if chezmoi needs installing / updating
if [[ "${chezmoi_installedver}" != "${chezmoi_latestver}" ]]; then
echo -e "\n${cyanbold}Install/update chezmoi${normal}"

# Define working directory and target file names
tmp_dir="${HOME}/git/${github_username}/${github_project}/tmp"
deb_file="chezmoi_${chezmoi_latestver}_linux_${pkgarch}.deb"
chk_file="chezmoi_${chezmoi_latestver}_checksums.txt"
sig_file="${chk_file}.sigstore.json"
pub_file="chezmoi_cosign.pub"
base_url="https://github.com/twpayne/chezmoi/releases/download/v${chezmoi_latestver}"

# Ensure availability of working folder for deb package installation
echo -e "$ mkdir -p ${tmp_dir}"
mkdir -p "${tmp_dir}"

echo -e "> Downloading chezmoi v${chezmoi_latestver} package and verification files"
curl -fsSL "${base_url}/${deb_file}" -o "${tmp_dir}/${deb_file}"
curl -fsSL "${base_url}/${chk_file}" -o "${tmp_dir}/${chk_file}"
curl -fsSL "${base_url}/${sig_file}" -o "${tmp_dir}/${sig_file}"
curl -fsSL "${base_url}/${pub_file}" -o "${tmp_dir}/${pub_file}"

# Verify the checksum file with cosign
echo -e "> Verifying release with cosign"
echo -e "$ cosign verify-blob \
--key \"${tmp_dir}/chezmoi_cosign.pub\" \
--bundle \"${tmp_dir}/${sig_file}\" \
\"${tmp_dir}/${chk_file}\"\n"
if cosign verify-blob \
    --key "${tmp_dir}/chezmoi_cosign.pub" \
    --bundle "${tmp_dir}/${sig_file}" \
    "${tmp_dir}/${chk_file}" &> /dev/null; then
    
    echo -e "${greenbold} ✅ Checksum file signature verified${normal}\n"
    echo -e "> Verifying deb package integrity"
    
    # Check the sha256 of the deb pkg
    echo -e "$ cd \"${tmp_dir}\" && sha256sum --ignore-missing -c \"${chk_file}\"\n"
    if ( cd "${tmp_dir}" && sha256sum --ignore-missing -c --status "${chk_file}" ); then
        echo -e "${greenbold} ✅ deb package integrity verified${normal}\n"
        echo -e "$ sudo dpkg -i \"${tmp_dir}/${deb_file}\"\n"
        sudo dpkg -i "${tmp_dir}/${deb_file}"
    else
        echo -e "${redbold} ⚠️ WARNING: deb package checksum failed${normal}\n"
        exit 101
    # Close sha256sum check
    fi
else
    echo -e "${redbold} ⚠️ WARNING: Signature verification failed${normal}\n"
    exit 102
# Close cosign check
fi

# Remove working folder at the end of the task
echo -e "$ rm -rf ${tmp_dir}"
rm -rf "${tmp_dir}"

# Close chezmoi not latest version check
fi

################################################################################
# WSL instance stop/start triggers this, making login autorun not so useful
################################################################################

# Create chezmoi update autorun at login if it does not exist or has changed

AUTORUN_DIR="${HOME}/.config/autostart"
DESKTOP_FILE="chezmoi-autorun.desktop"
DESKTOP_PATH="${AUTORUN_DIR}/${DESKTOP_FILE}"

DESKTOP_TEXT="\
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
NoDisplay=true
Exec=qterminal -e ${HOME}/.local/bin/upd
Name=Chezmoi update autorun
Comment=Autorun chezmoi update in QTerminal
Icon=utilities-terminal
Categories=System;Settings;Utility;Development;
"

if [ ! -s "${DESKTOP_PATH}" ] || \
! cmp -s <(printf "%s" "${DESKTOP_TEXT}") "${DESKTOP_PATH}"; then
echo -e "\n${cyanbold}‘Autorun chezmoi update in QTerminal’ desktop file${normal}"
echo -e "$ mkdir -p ${AUTORUN_DIR}"
mkdir -p "${AUTORUN_DIR}"
echo -e "$ printf \"%s\" \"\${DESKTOP_TEXT}\" > ${DESKTOP_PATH}"
printf "%s" "${DESKTOP_TEXT}" > "${DESKTOP_PATH}"
fi

################################################################################
# Overnight update not useful unless/until 1password and sudo are automatic
################################################################################

# Create systemd service if it does not exist or has changed

SERVICE_DIR="${HOME}/.config/systemd/user"
SERVICE_FILE="chezmoi-update.service"
SERVICE_PATH="${SERVICE_DIR}/${SERVICE_FILE}"

SERVICE_TEXT="\
[Unit]
Description=Run chezmoi update in QTerminal
After=graphical-session.target

[Service]
Type=oneshot
# Check if the GUI is active. If inactive (exit code 3), skip cleanly.
ExecCondition=/usr/bin/systemctl --user is-active graphical-session.target
ExecStart=/usr/bin/qterminal -e %h/.local/bin/upd
"

if [ ! -s "${SERVICE_PATH}" ] || \
! cmp -s <(printf "%s" "${SERVICE_TEXT}") "${SERVICE_PATH}"; then
echo -e "\n${cyanbold}Systemd service: chezmoi update${normal}"
echo -e "$ mkdir -p ${SERVICE_DIR}"
mkdir -p "${SERVICE_DIR}"
echo -e "$ printf \"%s\" \"\${SERVICE_TEXT}\" > ${SERVICE_PATH}"
printf "%s" "${SERVICE_TEXT}" > "${SERVICE_PATH}"
RELOAD_SYSTEMD=1
fi

# Create systemd timer if it does not exist or has changed

TIMER_DIR="${HOME}/.config/systemd/user"
TIMER_FILE="chezmoi-update.timer"
TIMER_PATH="${TIMER_DIR}/${TIMER_FILE}"

TIMER_TEXT="\
[Unit]
Description=Run chezmoi update at 2 AM daily

[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=false

[Install]
WantedBy=timers.target
"

if [ ! -s "${TIMER_PATH}" ] || \
! cmp -s <(printf "%s" "${TIMER_TEXT}") "${TIMER_PATH}"; then
echo -e "\n${cyanbold}Systemd timer: chezmoi update${normal}"
echo -e "$ mkdir -p ${TIMER_DIR}"
mkdir -p "${TIMER_DIR}"
echo -e "$ printf \"%s\" \"\${TIMER_TEXT}\" > ${TIMER_PATH}"
printf "%s" "${TIMER_TEXT}" > "${TIMER_PATH}"
RELOAD_SYSTEMD=1
fi

if (( RELOAD_SYSTEMD == 1 )); then
echo -e "$ systemctl --user daemon-reload"
systemctl --user daemon-reload
echo -e "$ systemctl --user enable --now ${TIMER_FILE}"
systemctl --user enable --now "${TIMER_FILE}"
fi

################################################################################

# Log this latest `Config` operation and display runtime

echo -e "\n${bluebold}${local_filename} run at${normal}"
echo -e "> ${runtime}\n"
mkdir -p "${HOME}/git/${github_username}/${github_project}" && \
echo -e "EXEC-TIME: ${runtime} | FILE: ${local_filename}" \
>> "${HOME}/git/${github_username}/${github_project}/config-runs.log"

################################################################################
#
# Line wrap ruler
#
#   5   10   15   20   25   30   35   40   45   50   55   60   65   70   75   80
#
################################################################################

