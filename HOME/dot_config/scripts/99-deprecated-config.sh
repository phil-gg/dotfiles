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
# Prioritising Microsoft's proprietary WSLg graphics libraries over the native #
# open-source Mesa libraries broke KWin nesting inside Weston                  #
################################################################################

multiarch=$(dpkg-architecture -q DEB_HOST_MULTIARCH)
libdir="/usr/lib/${multiarch}"

# Note GBM may not do much in this set-up, but there were dri/drm name issues
# before Mesa 24
# /usr/lib/x86_64-linux-gnu/gbm/dri_gbm.so must exist (installed with apt)
if [ -e "${libdir}/gbm/dri_gbm.so" ]; then
if [ ! -L "${libdir}/gbm/drm_gbm.so" ] \
|| [ ! -L "${libdir}/dri/dri_gbm.so" ] \
|| [ ! -L "${libdir}/dri/drm_gbm.so" ]; then

echo -e "\n${cyanbold}Create symlinks to gbm/dri_gbm.so${normal}"
# Quietly ensure other folder exists (but should already be there)
sudo mkdir -p "${libdir}/dri"

if [ ! -L "${libdir}/gbm/drm_gbm.so" ]; then
echo -e "$ sudo ln -s ${libdir}/gbm/dri_gbm.so ${libdir}/gbm/drm_gbm.so"
sudo ln -sf "${libdir}/gbm/dri_gbm.so" "${libdir}/gbm/drm_gbm.so"
fi

if [ ! -L "${libdir}/dri/dri_gbm.so" ]; then
echo -e "$ sudo ln -s ${libdir}/gbm/dri_gbm.so ${libdir}/dri/dri_gbm.so"
sudo ln -sf "${libdir}/gbm/dri_gbm.so" "${libdir}/dri/dri_gbm.so"
fi

if [ ! -L "${libdir}/dri/drm_gbm.so" ]; then
echo -e "$ sudo ln -s ${libdir}/gbm/dri_gbm.so ${libdir}/dri/drm_gbm.so"
sudo ln -sf "${libdir}/gbm/dri_gbm.so" "${libdir}/dri/drm_gbm.so"
fi

# Update the linker cache so the system sees the new libs immediately
echo -e "$ sudo ldconfig"
sudo ldconfig

fi
fi

# Ensure system libraries are loaded.
# This stops the following environment variable from being needed:
# LD_LIBRARY_PATH=/usr/lib/wsl/lib:/usr/lib/x86_64-linux-gnu/dri

if [ ! -s "/etc/ld.so.conf.d/phil-wslg.conf" ] || \
[ ! -s "/etc/ld.so.conf.d/phil-dri-gbm.conf" ]; then

echo -e "\n${cyanbold}Configuring system library paths${normal}"
# Quietly ensure folder exists (but should already be there)
sudo mkdir -p /etc/ld.so.conf.d

if [ ! -s "/etc/ld.so.conf.d/phil-wslg.conf" ]; then
echo -e "$ echo /usr/lib/wsl/lib | sudo tee /etc/ld.so.conf.d/phil-wslg.conf"
echo /usr/lib/wsl/lib | sudo tee /etc/ld.so.conf.d/phil-wslg.conf > /dev/null
fi

if [ ! -s "/etc/ld.so.conf.d/phil-dri-gbm.conf" ]; then
echo -e "$ echo ${libdir}/dri | sudo tee /etc/ld.so.conf.d/phil-dri-gbm.conf"
echo "${libdir}/dri" | sudo tee /etc/ld.so.conf.d/phil-dri-gbm.conf > /dev/null
fi

# Update the linker cache so the system sees the new libs immediately
echo -e "$ sudo ldconfig"
sudo ldconfig

fi

################################################################################
# Deprecated when weston replaced with cage (July 2026)
################################################################################

# Create /etc/xdg/weston/weston.ini if it does not exist or has changed

WESTON_DIR="/etc/xdg/weston"
WESTON_FILE="${WESTON_DIR}/weston.ini"

WESTON_TEXT="\
[core]
# https://manpages.debian.org/trixie/weston/weston.ini.5.en.html
# All Weston-KWin comms are via Wayland, with Xwayland only enabled in KWin, so this is off
xwayland=false
# Force wayland backend
backend=wayland
# Use the Kiosk shell to force the nested app to fill the screen
shell=kiosk-shell.so
# Load the systemd notification module
modules=systemd-notify.so
# Set output repaint window to 8 ms maximum, which should support up to 125 Hz display refresh rates
repaint-window=8
# Disable screen blanking
idle-time=0
# Force graphics acceleration
renderer=gl

[libinput]
# Enables tap to click on touchpad devices
enable-tap=true
# Enables tap and drag on touchpad devices
tap-and-drag=true
# Disable other devices while typing on keyboard
disable-while-typing=false
# Disable clicking both left and right buttons together simulating middle click
middle-button-emulation=false
# Enable touchscreen calibrator interface
touchscreen_calibrator=false

[shell]
# Set background color to opaque black
background-color=0xff000000
# Enables screen locking (Boolean)
locking=false
# Opening new windows animation
animation=none
# Closing windows animation
close-animation=none
# Effect used by desktop-shell when starting up
startup-animation=none
# Effect used with focused vs unfocused windows
focus-animation=dim-layer
# Weston quits when the Ctrl-Alt-Backspace key combination is pressed
allow-zap=false
# Modifier key for bindings - see https://manpages.debian.org/trixie/weston/weston-bindings.7.en.html
binding-modifier=alt
# Set the cursor theme
cursor-theme=westonCursor
# Set the cursor size
cursor-size=96

[keyboard]
keymap_model=pc105
keymap_layout=gb
keymap_variant=extd
"

if [ ! -s "${WESTON_FILE}" ] || \
! cmp -s <(printf "%s" "${WESTON_TEXT}") "${WESTON_FILE}"; then
echo -e "\n${cyanbold}Configure weston${normal}"
echo -e "$ sudo mkdir -p ${WESTON_DIR}"
sudo mkdir -p "${WESTON_DIR}"
echo -e "$ printf \"%s\" \"\${WESTON_TEXT}\" | sudo tee ${WESTON_FILE} > \
/dev/null"
printf "%s" "${WESTON_TEXT}" | sudo tee "${WESTON_FILE}" > /dev/null
echo -e "$ ln -sf ${WESTON_FILE} ~/.config/weston.ini"
ln -sf "${WESTON_FILE}" "${HOME}/.config/weston.ini"
fi

# Define systemd unit for Weston (Plow)

WESTON_SERVICE="\
# plow-weston.service
# Just a virtual display
# A customised /usr/lib/systemd/user/plasma-kwin_wayland.service depends on this

[Unit]
Description=Weston compositor (nested on WSLg)
# https://manpages.debian.org/trixie/weston/weston.1.en.html
Documentation=man:weston(1)
After=graphical-session-pre.target
# For teardown, stop plow-weston with plasma-kwin_wayland.service
PartOf=plasma-kwin_wayland.service

[Service]
Type=notify
# This is the command to start the service
ExecStart=/usr/bin/weston --socket=weston --width=2112 --height=1320
# %t resolves to /run/user/$ (id -u)
ExecStopPost=/bin/rm -f %t/weston %t/weston.lock
Restart=no
"

WESTON_UNIT_DIR="/etc/systemd/user"
WESTON_UNIT_FILE="${WESTON_UNIT_DIR}/plow-weston.service"

# Configure plow-weston.service systemd unit
if [ ! -s "${WESTON_UNIT_FILE}" ] || \
! cmp -s <(printf "%s" "${WESTON_SERVICE}") "${WESTON_UNIT_FILE}"; then
echo -e "\n${cyanbold}Configure plow-weston.service systemd unit${normal}"
# Choosing to expand path but not file contents in echo output here
# Hence backslash escapes for WESTON_SERVICE variable
echo -e "$ printf \"%s\" \"\${WESTON_SERVICE}\" | sudo tee ${WESTON_UNIT_FILE} \
> /dev/null"
printf "%s" "${WESTON_SERVICE}" | sudo tee "${WESTON_UNIT_FILE}" > /dev/null
USR_UNITS_CHANGED=1
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

