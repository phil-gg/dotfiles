#!/bin/bash

################################################################################
# Configure repos & packages on Debian in an idempotent manner.
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
git_filename="run_always_before_02-configure-repos-update-pkgs-Debian.sh"
local_filename="02-configure-repos-update-pkgs-Debian.sh"
runtime=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
normal=$(printf '\033[0m')
redbold=$(printf '\033[91;1m')
greenbold=$(printf '\033[92;1m')
cyanbold=$(printf '\033[96;1m')
bluebold=$(printf '\033[94;1m')
pkgarch=$(dpkg --print-architecture)

# Now running `${local_filename}`

echo -e "\n${bluebold}Now running ‘${local_filename}’${normal}"

# Get debian package keys

if [[ ! -f /usr/share/keyrings/trixie-debian-archive-keyring.asc
   || ! -f /usr/share/keyrings/trixie-security-archive-keyring.asc
   || ! -f /usr/share/keyrings/trixie-release-keyring.asc ]]; then
echo -e "\n${cyanbold}Downloading debian signing keys${normal}"
fi

if [[ ! -f /usr/share/keyrings/trixie-debian-archive-keyring.asc ]]; then
echo -e "$ \
wget -qO- https://ftp-master.debian.org/keys/archive-key-13.asc | \
sudo tee /usr/share/keyrings/trixie-debian-archive-keyring.asc 1> /dev/null"
wget -qO- https://ftp-master.debian.org/keys/archive-key-13.asc | \
sudo tee /usr/share/keyrings/trixie-debian-archive-keyring.asc 1> /dev/null
fi

if [[ ! -f /usr/share/keyrings/trixie-security-archive-keyring.asc ]]; then
echo -e "$ \
wget -qO- https://ftp-master.debian.org/keys/archive-key-13-security.asc | \
sudo tee /usr/share/keyrings/trixie-security-archive-keyring.asc 1> /dev/null"
wget -qO- https://ftp-master.debian.org/keys/archive-key-13-security.asc | \
sudo tee /usr/share/keyrings/trixie-security-archive-keyring.asc 1> /dev/null
fi

if [[ ! -f /usr/share/keyrings/trixie-release-keyring.asc ]]; then
echo -e "$ \
wget -qO- https://ftp-master.debian.org/keys/release-13.asc | \
sudo tee /usr/share/keyrings/trixie-release-keyring.asc 1> /dev/null"
wget -qO- https://ftp-master.debian.org/keys/release-13.asc | \
sudo tee /usr/share/keyrings/trixie-release-keyring.asc 1> /dev/null
fi

# Check debian package keys

echo -e "\n${cyanbold}Checking debian package signing keys${normal}"

expectedsha256trixiearchive="6f1d277429dd7ffedcc6f8688a7ad9a458859b1139ffa026\
d1eeaadcbffb0da7"
expectedsha256trixiesecurity="844c07d242db37f283afab9d5531270a0550841e90f9f1a9\
c3bd599722b808b7"
expectedsha256trixierelease="4d097bb93f83d731f475c5b92a0c2fcf108cfce1d4932792\
fca72d00b48d198b"

expectedkeytrixiearchive="04B54C3CDCA79751B16BC6B5225629DF75B188BD"
expectedkeytrixiesecurity="5E04A1E3223A19A20706E20F9904613D4CCE68C6"
expectedkeytrixierelease="41587F7DB8C774BCCF131416762F67A0B2C39DE4"

actualsha256trixiearchive=$(sha256sum /usr/share/keyrings/trixie-debian-\
archive-keyring.asc 2> /dev/null | grep -oE "[0-9a-f]{64}")
actualsha256trixiesecurity=$(sha256sum /usr/share/keyrings/trixie-security-\
archive-keyring.asc 2> /dev/null | grep -oE "[0-9a-f]{64}")
actualsha256trixierelease=$(sha256sum /usr/share/keyrings/trixie-release-\
keyring.asc 2> /dev/null | grep -oE "[0-9a-f]{64}")

actualkeytrixiearchive=$(gpg --no-default-keyring --with-colons \
--import-options show-only --import /usr/share/keyrings/trixie-debian-archive\
-keyring.asc 2> /dev/null | awk -F':' '$1=="fpr"{print $10}' | head -n 1)
actualkeytrixiesecurity=$(gpg --no-default-keyring --with-colons \
--import-options show-only --import /usr/share/keyrings/trixie-security-archive\
-keyring.asc 2> /dev/null | awk -F':' '$1=="fpr"{print $10}' | head -n 1)
actualkeytrixierelease=$(gpg --no-default-keyring --with-colons \
--import-options show-only --import /usr/share/keyrings/trixie-release\
-keyring.asc 2> /dev/null | awk -F':' '$1=="fpr"{print $10}' | head -n 1)

echo -e "\n 🔑 /usr/share/keyrings/trixie-debian-archive-keyring.asc"
echo -e " 🔤 ${expectedsha256trixiearchive}"
if [[ "${expectedsha256trixiearchive}" == "${actualsha256trixiearchive}" ]];
then
echo -e "${greenbold} ✅ The SHA256 hash matches${normal}"
else
echo -e "${redbold} ⚠️ WARNING: unexpected SHA256 hash${normal}\n"
exit 101
fi
echo -e " 🔐 ${expectedkeytrixiearchive}"
if [[ "${expectedkeytrixiearchive}" == "${actualkeytrixiearchive}" ]];
then
echo -e "${greenbold} ✅ The key fingerprint matches${normal}"
else
echo -e "${redbold} ⚠️ WARNING: unexpected fingerprint${normal}\n"
exit 102
fi

echo -e "\n 🔑 /usr/share/keyrings/trixie-security-archive-keyring.asc"
echo -e " 🔤 ${expectedsha256trixiesecurity}"
if [[ "${expectedsha256trixiesecurity}" == "${actualsha256trixiesecurity}" ]];
then
echo -e "${greenbold} ✅ The SHA256 hash matches${normal}"
else
echo -e "${redbold} ⚠️ WARNING: unexpected SHA256 hash${normal}\n"
exit 103
fi
echo -e " 🔐 ${expectedkeytrixiesecurity}"
if [[ "${expectedkeytrixiesecurity}" == "${actualkeytrixiesecurity}" ]];
then
echo -e "${greenbold} ✅ The key fingerprint matches${normal}"
else
echo -e "${redbold} ⚠️ WARNING: unexpected fingerprint${normal}\n"
exit 104
fi

echo -e "\n 🔑 /usr/share/keyrings/trixie-release-keyring.asc"
echo -e " 🔤 ${expectedsha256trixierelease}"
if [[ "${expectedsha256trixierelease}" == "${actualsha256trixierelease}" ]];
then
echo -e "${greenbold} ✅ The SHA256 hash matches${normal}"
else
echo -e "${redbold} ⚠️ WARNING: unexpected SHA256 hash${normal}\n"
exit 105
fi
echo -e " 🔐 ${expectedkeytrixierelease}"
if [[ "${expectedkeytrixierelease}" == "${actualkeytrixierelease}" ]];
then
echo -e "${greenbold} ✅ The key fingerprint matches${normal}"
else
echo -e "${redbold} ⚠️ WARNING: unexpected fingerprint${normal}\n"
exit 106
fi

# Add mozilla package key (on any arch)

expectedMozillaKey="35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3"

actualMozillaKey=$(gpg --no-default-keyring --with-colons --import-options \
show-only --import /usr/share/keyrings/mozilla-archive-keyring.asc \
2> /dev/null | awk -F':' '$1=="fpr"{print $10}' | head -n 1)

if [[ "${actualMozillaKey}" != "${expectedMozillaKey}" ]]; then

echo -e "\n${cyanbold}Add Mozilla signing key${normal}"
echo -e "$ wget -qO- https://packages.mozilla.org/apt/repo-signing-key.gpg | \
sudo tee /usr/share/keyrings/mozilla-archive-keyring.asc 1> /dev/null"
wget -qO- https://packages.mozilla.org/apt/repo-signing-key.gpg | \
sudo tee /usr/share/keyrings/mozilla-archive-keyring.asc 1> /dev/null

actualMozillaKey=$(gpg --no-default-keyring --with-colons --import-options \
show-only --import /usr/share/keyrings/mozilla-archive-keyring.asc \
2> /dev/null | awk -F':' '$1=="fpr"{print $10}' | head -n 1)

fi

echo -e "\n 🔑 /usr/share/keyrings/mozilla-archive-keyring.asc"
echo -e " 🔐 ${expectedMozillaKey}"
if [[ "${expectedMozillaKey}" == "${actualMozillaKey}" ]];
then
echo -e "${greenbold} ✅ The key fingerprint matches${normal}"
else
echo -e "${redbold} ⚠️ WARNING: unexpected fingerprint${normal}\n"
exit 107
fi

# Add 1password package key (on amd64 arch only)

if [[ "${pkgarch}" == "amd64" ]]; then

expected1passwordKey="3FEF9748469ADBE15DA7CA80AC2D62742012EA22"

actual1passwordKey=$(gpg --no-default-keyring --with-colons --import-options \
show-only --import /usr/share/keyrings/1password-archive-keyring.gpg \
2> /dev/null | awk -F':' '$1=="fpr"{print $10}' | head -n 1)

if [[ "${actual1passwordKey}" != "${expected1passwordKey}" ]]; then

# gpg not asc key to match built-in 1password config

echo -e "\n${cyanbold}Add 1password signing key${normal}"
echo -e "wget -qO- https://downloads.1password.com/linux/keys/1password.asc | \
sudo gpg --yes --no-default-keyring --dearmor --output \
/usr/share/keyrings/1password-archive-keyring.gpg"
wget -qO- https://downloads.1password.com/linux/keys/1password.asc | \
sudo gpg --yes --no-default-keyring --dearmor --output \
/usr/share/keyrings/1password-archive-keyring.gpg

actual1passwordKey=$(gpg --no-default-keyring --with-colons --import-options \
show-only --import /usr/share/keyrings/1password-archive-keyring.gpg \
2> /dev/null | awk -F':' '$1=="fpr"{print $10}' | head -n 1)

fi

echo -e "\n 🔑 /usr/share/keyrings/1password-archive-keyring.gpg"
echo -e " 🔐 ${expected1passwordKey}"
if [[ "${expected1passwordKey}" == "${actual1passwordKey}" ]];
then
echo -e "${greenbold} ✅ The key fingerprint matches${normal}"
else
echo -e "${redbold} ⚠️ WARNING: unexpected fingerprint${normal}\n"
exit 108
fi

fi

# modernise deb package config files

if [[ -f /etc/apt/sources.list
   || ! -f /etc/apt/preferences.d/01-pin-prefs
   || ! -f /etc/apt/sources.list.d/01-trixie-security.sources
   || ! -f /etc/apt/sources.list.d/02-trixie-debian.sources
   || ! -f /etc/apt/sources.list.d/99-sid-debian.sources ]]; then
echo -e "\n${cyanbold}Updating package sources to deb822 format${normal}"
fi

if [[ -f /etc/apt/sources.list ]]; then
echo -e "$ sudo rm /etc/apt/sources.list"
sudo rm /etc/apt/sources.list
fi

# Set apt pinning preferences

if command -v wslinfo &> /dev/null; then
WSL_PREFS="\
Explanation: Don't want network manager on plasma when runing inside WSL2
Package: plasma-nm
Pin: version *
Pin-Priority: -1

Explanation: Don't want power management within plasma when runing inside WSL2
Package: powerdevil
Pin: version *
Pin-Priority: -1

Explanation: Don't want bluetooth within plasma when runing inside WSL2
Package: bluedevil
Pin: version *
Pin-Priority: -1

Explanation: Don't want to screenshare X11 apps within plasma on WSL2
Explanation: (and presence of this pkg causes other problems on WSL2)
Package: xwaylandvideobridge
Pin: version *
Pin-Priority: -1
"
else
WSL_PREFS="\
Explanation: NO negative pin priorities here preventing package installation
"
fi

PIN_PREFS=$( cat << EOF
Explanation: This file is /etc/apt/preferences.d/01-pin-prefs
Explanation: https://manpages.debian.org/trixie/apt/apt_preferences.5.en.html
Explanation: Pin-Priority is the primary form of package prioritisation
Explanation: Thereafter install higher version of packages with same priority
Explanation: See the following URL for Debian package cycle for repositories:
Explanation: https://salsa.debian.org/debian/package-cycle/-/blob/master/package-cycle.svg
Explanation: Priorities over 1000 forces install even for a downgrade
Explanation: Currently NO packages are set with Pin-Priorities over 1000
Explanation: 991-1000 beats target release unless installed a higher version
Explanation: Currently NO packages are set with Pin-Priorities 991-1000
Explanation: Target release priority is 990
Explanation: Trixie/Stable is here at 980 just less than target release priority
Package: *
Pin: release o=Debian, n=trixie-security
Pin-Priority: 980

Explanation: Trixie/Stable is here at 980 just less than target release priority
Package: *
Pin: release o=Debian, n=trixie
Pin-Priority: 980

Explanation: Trixie/Stable is here at 980 just less than target release priority
Package: *
Pin: release o=Debian, n=trixie-updates
Pin-Priority: 980

Explanation: Trixie/Stable is here at 980 just less than target release priority
Package: *
Pin: release o=Debian, n=trixie-proposed-updates
Pin-Priority: 980

Explanation: Prioritise 1password repo just less than Trixie/Stable
Package: *
Pin: origin "downloads.1password.com"
Pin-Priority: 970

Explanation: Prioritise mozilla repo just less than Trixie/Stable
Package: *
Pin: origin "packages.mozilla.org"
Pin-Priority: 970

Explanation: Add any more third-party repos just above here
Explanation: trixie-backports is here at 510 just more than default priority
Package: *
Pin: release o=Debian Backports, n=trixie-backports
Pin-Priority: 510

Explanation: Default (with no pin or target release) priority is 500
Explanation: Stable backports sloppy is here at 120 for selected packages only
Explanation: *NOTE* Remove all sloppy packages before distribution upgrade
Package: *
Pin: release o=Debian Backports, n=trixie-backports-sloppy
Pin-Priority: 120

Explanation: Sid/Unstable is here at 110 for selected packages only
Package: *
Pin: release o=Debian, n=sid
Pin-Priority: 110

Explanation: Installed packages have priority 100
Explanation: Currently NO packages are set with Pin-Priorities 1-100
Explanation: Warning; Pin-Priority=0 has undefined behaviour; do not use
Explanation: Negative pin priorities prevent package installation
${WSL_PREFS}
EOF
)

if [[ ! -f /etc/apt/preferences.d/01-pin-prefs || \
! cmp -s <(echo -e "${PIN_PREFS}") /etc/apt/preferences.d/01-pin-prefs ]];
then
echo -e "\n${cyanbold}Updating /etc/apt/preferences.d/01-pin-prefs${normal}"
echo -e "$ echo -e \"\${PIN_PREFS}\" | \
sudo tee /etc/apt/preferences.d/01-pin-prefs 1> /dev/null"
echo -e "${PIN_PREFS}" | \
sudo tee /etc/apt/preferences.d/01-pin-prefs 1> /dev/null
fi

if [[ ! -f /etc/apt/sources.list.d/01-trixie-security.sources ]]; then
echo -e "> Create /etc/apt/sources.list.d/01-trixie-security.sources"
echo -e "\
# Config to save at /etc/apt/sources.list.d/01-trixie-security.sources
# This replaces /etc/apt/sources.list
# debian repo available types: deb deb-src
# trixie available components: main contrib non-free-firmware non-free
# trixie available architectures: amd64 arm64 armel armhf i386 ppc64el riscv64 \
s390x
Types: deb
URIs: https://security.debian.org/debian-security/
Suites: trixie-security
Components: main contrib non-free-firmware non-free
Architectures: ${pkgarch}
Signed-By: /usr/share/keyrings/trixie-security-archive-keyring.asc
" | sudo tee /etc/apt/sources.list.d/01-trixie-security.sources 1> /dev/null
fi

if [[ ! -f /etc/apt/sources.list.d/02-trixie-debian.sources ]]; then
echo -e "> Create /etc/apt/sources.list.d/02-trixie-debian.sources"
echo -e "\
# Config to save at /etc/apt/sources.list.d/02-trixie-debian.sources
# This replaces /etc/apt/sources.list
# debian repo available types: deb deb-src
# available suites: trixie trixie-updates trixie-proposed-updates \
trixie-backports trixie-backports-sloppy
# - backports are testing (forky) packages, rebuilt for stable (trixie), that \
don't exceed release version for testing (forky)
# - backports-sloppy are testing (forky) packages, rebuilt for stable (trixie),
#  …but with higher version numbers that would break an upgrade to forky
# - trixie-backports-sloppy has low pin priority set in apt preferences
# - Install from backports-sloppy with \"sudo apt install packagename/trixie-\
backports-sloppy\"
# available components: main contrib non-free-firmware non-free
# available architectures: amd64 arm64 armel armhf i386 ppc64el riscv64 s390x
Types: deb
URIs: https://deb.debian.org/debian/
Suites: trixie trixie-updates trixie-proposed-updates trixie-backports \
trixie-backports-sloppy
Components: main contrib non-free-firmware non-free
Architectures: ${pkgarch}
Signed-By: /usr/share/keyrings/trixie-debian-archive-keyring.asc\
" | sudo tee /etc/apt/sources.list.d/02-trixie-debian.sources 1> /dev/null
fi

if [[ ! -f /etc/apt/sources.list.d/99-sid-debian.sources ]]; then
echo -e "> Create /etc/apt/sources.list.d/99-sid-debian.sources"
echo -e "\
# Config to save at /etc/apt/sources.list.d/99-sid-debian.sources
# This replaces /etc/apt/sources.list
# debian repo available types: deb deb-src
# available suites: sid
# - Sid/Unstable has low pin priority set in apt preferences
# - Install from sid with \"sudo apt install packagename/sid\"
# available components: main contrib non-free-firmware non-free
# available architectures: amd64 arm64 armhf i386 loong64 ppc64el riscv64 \
s390x
Types: deb
URIs: https://deb.debian.org/debian/
Suites: sid
Components: main contrib non-free-firmware non-free
Architectures: ${pkgarch}
Signed-By: /usr/share/keyrings/trixie-debian-archive-keyring.asc\
" | sudo tee /etc/apt/sources.list.d/99-sid-debian.sources 1> /dev/null
fi

# Install mozilla deb repo (on any arch)

if [[ ! -f /etc/apt/sources.list.d/03-mozilla.sources ]]; then
echo -e "\n${bluebold}Create /etc/apt/sources.list.d/03-mozilla.sources\
${normal}\n"
echo -e "\
# Mozilla apt package repository
Types: deb
URIs: https://packages.mozilla.org/apt
Suites: mozilla
Components: main
Architectures: ${pkgarch}
Signed-By: /usr/share/keyrings/mozilla-archive-keyring.asc\
" | sudo tee /etc/apt/sources.list.d/03-mozilla.sources 1> /dev/null
fi

# Install 1password deb repo (on amd64 arch only)

if [[ "${pkgarch}" == "amd64" && ! -f /etc/apt/sources.list.d/1password.list ]];
then
echo -e "\n${bluebold}Create /etc/apt/sources.list.d/1password.list\
${normal}\n"

# Can't use this new format until built-in 1password config updates
: ' deb822 CONFIG
# /etc/apt/sources.list.d/1password.sources
# 1password debian repository
Types: deb
URIs: https://downloads.1password.com/linux/debian/amd64
Suites: stable
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/1password-archive-keyring.asc
'
: ' MATCHING KEY
wget -qO- https://downloads.1password.com/linux/keys/1password.asc | \
sudo tee /usr/share/keyrings/1password-archive-keyring.asc 1> /dev/null
'

echo -e "deb [arch=amd64 \
signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] \
https://downloads.1password.com/linux/debian/amd64 stable main" | \
sudo tee /etc/apt/sources.list.d/1password.list 1> /dev/null

# Configure debsig policy for repos that support it
# (currently only 1Password so can't be turned on globally)

onepname="1password"
onepid=$(gpg --list-packets /usr/share/keyrings/1password-archive-keyring.gpg \
| awk '$1=="keyid:"{print$2}' | head -n 1)

if [[ ! -f "/etc/debsig/policies/${onepid}/${onepname}.pol"
   || ! -f "/usr/share/debsig/keyrings/${onepid}/debsig.gpg" ]]; then
echo -e "\n${bluebold}Set debsig policy for ${onepname}${normal}\n"
echo -e "> Create /usr/share/debsig/keyrings/${onepid}/debsig.gpg\n"
sudo mkdir -p "/etc/debsig/policies/${onepid}"
echo -e "\
<?xml version=\"1.0\"?>
<!DOCTYPE Policy SYSTEM \"https://www.debian.org/debsig/1.0/policy.dtd\">
<Policy xmlns=\"https://www.debian.org/debsig/1.0/\">
    <Origin Name=\"${onepname}\" id=\"${onepid}\"/>
    <Selection>
        <Required Type=\"origin\" File=\"debsig.gpg\" id=\"${onepid}\"/>
    </Selection>
    <Verification MinOptional=\"0\">
        <Required Type=\"origin\" File=\"debsig.gpg\" id=\"${onepid}\"/>
    </Verification>
</Policy>" \
| sudo tee "/etc/debsig/policies/${onepid}/${onepname}.pol" 1> /dev/null
sudo mkdir -p "/usr/share/debsig/keyrings/${onepid}"
echo -e "\n> Create usr/share/debsig/keyrings/${onepid}/debsig.gpg"
sudo cp /usr/share/keyrings/1password-archive-keyring.gpg \
"/usr/share/debsig/keyrings/${onepid}/debsig.gpg"
fi
fi

# Update apt if last `sudo apt update` more than one hour ago

now=$(date +%s)
last_update=$(stat -c %Y /var/cache/apt/pkgcache.bin 2>/dev/null || echo 0)
if (( now - last_update > 3600 )); then
echo -e "\n${cyanbold}Update apt${normal}"
echo -e "$ sudo apt update\n"
sudo apt update
fi

# apt upgrade if needed

count_upgradable_pkgs=$(apt list --upgradable 2> /dev/null | \
grep -c -v "^Listing") 
if (( count_upgradable_pkgs > 0 )); then
echo -e "\n${cyanbold}Run apt upgrade${normal}"
echo -e "$ sudo apt upgrade -y\n"
sudo apt upgrade -y
fi

# Check for packages and install if necessary
# Before network test, because network test uses wget
# Include one named terminal emulator here to prevent auto-install of other
# terminal emulator applications by x-terminal-emulator virtual package later
# Foot is a high-performance, wayland first/only, terminal emulator

PACKAGES=(
curl
wget
git
gh
gpg
debsigs
lynx
equivs
foot
)

DPKG_OUTPUT=$(dpkg-query -W -f='${db:Status-Status} ${Package}\n' \
"${PACKAGES[@]}" 2> /dev/null)
DPKG_ERROR=$?
if [[ "${DPKG_ERROR}" -eq 0 ]]; then
APT_REQD=$(echo "${DPKG_OUTPUT}" | awk '$1 != "installed" {print $2}')
fi

if [[ -n "${APT_REQD}" || "${DPKG_ERROR}" -ne 0 ]]; then
echo -e "\n${cyanbold}Installing packages${normal}"
echo -e "$ sudo apt install -y ${PACKAGES[@]}"
sudo apt install -y "${PACKAGES[@]}"
fi

# Get latest 1password versions

echo -e "\n${cyanbold}Latest status message for 1password linux stable${normal}"
echo -e "> See https://releases.1password.com/linux/stable"
longversion1p=$(lynx -dump https://releases.1password.com/linux/stable \
| grep -oE "Updated\sto.*$")
shortversion1p=$(echo -e "${longversion1p}" | grep -oE "[0-9]+\.[0-9\.]+")
echo -e "> ${longversion1p}"

echo -e "\n${cyanbold}Latest status message for 1password-cli${normal}"
echo -e "> See https://app-updates.agilebits.com"
shortver1pcli=$(lynx -dump https://app-updates.agilebits.com | grep -C 2 -E \
"^\s*?1Password CLI\s*?$" | grep -oE "[0-9]+\.[0-9]+\.[0-9]+")
echo -e "> ${shortver1pcli}"

# ################## #
# ON AMD64 ARCH ONLY #
# ################## #
if [[ "${pkgarch}" == "amd64" ]]; then

# debian packages available on amd64 only

echo -e "\n${cyanbold}Installed 1password debian package versions${normal}"
installedversion1p=$(apt-cache policy 1password | grep Installed | \
awk -F ': ' '{print $2}')
installedver1pcli=$(apt-cache policy 1password-cli | grep Installed | \
awk -F ': ' '{print $2}')
echo -e "> ${installedversion1p:-${bluebold}(none)${normal}} = 1password"
echo -e "> ${installedver1pcli:-${bluebold}(none)${normal}} = 1password-cli"

# Install 1password

echo -e "\n${cyanbold}Checking if 1password is upgradable${normal}"
echo -e "$ sudo apt update"

opguidpkgcheck=$(dpkg -s 1password 2> /dev/null | grep "Package: 1password")
opclidpkgcheck=$(dpkg -s 1password-cli 2> /dev/null \
| grep "Package: 1password-cli")
opupdatecheck=$(apt list --upgradable 2>&1 \
| grep -vE "Use with caution in scripts|Listing" \
| grep -o "1password" \
| head -c 9)

if [[ "${opupdatecheck}" == "1password"
   || "${opguidpkgcheck}" != "Package: 1password"
   || "${opclidpkgcheck}" != "Package: 1password-cli" ]]; then
echo -e "\n${cyanbold}Installing 1password${normal}"
echo -e "$ sudo apt update && sudo apt -y install 1password 1password-cli\n"
sudo apt update && sudo apt -y install 1password 1password-cli
else
echo -e "${greenbold}> 1password & 1password-cli are up-to-date${normal}"
fi

# ###################### #
# END AMD64 ONLY SECTION #
# ###################### #
fi

# ################## #
# ON ARM64 ARCH ONLY #
# ################## #

# Ignore this section, it is not complete, and not executed
#
# if [[ "${pkgarch}" == "arm64" ]]; then
# 
# # TO-DO: 1password & 1password-cli versions without looking at deb packages
# 
# # Explicitly install 1password dependencies
# 
# echo -e "\n${cyanbold}Explicitly install 1password dependencies${normal}"
# echo -e "${cyanbold}( this dependency list was extracted from deb file in \
# Oct-2025 )${normal}"
# echo -e "${cyanbold}( https://downloads.1password.com/linux/debian/amd64/stable\
# /1password-latest.deb )${normal}"
# echo -e "
# sudo apt -y install \\
# curl \\
# gnupg2 \\
# libasound2 \\
# libatk-bridge2.0-0 \\
# libatk1.0-0 \\
# libc6 \\
# libcurl4 \\
# libdrm2 \\
# libgbm1 \\
# libgtk-3-0 \\
# libnotify4 \\
# libnss3 \\
# libxcb-shape0 \\
# libxcb-xfixes0 \\
# libxshmfence1 \\
# libudev1 \\
# xdg-utils \\
# libappindicator3-1\
# \n"
# sudo apt -y install \
# curl \
# gnupg2 \
# libasound2 \
# libatk-bridge2.0-0 \
# libatk1.0-0 \
# libc6 \
# libcurl4 \
# libdrm2 \
# libgbm1 \
# libgtk-3-0 \
# libnotify4 \
# libnss3 \
# libxcb-shape0 \
# libxcb-xfixes0 \
# libxshmfence1 \
# libudev1 \
# xdg-utils \
# libappindicator3-1
# 
# # Make folder(s) if they don't exist
# 
# if [ ! -d "${HOME}/git/${github_username}/${github_project}/tmp" ]; then
# echo -e "\n${cyanbold}Build our own deb package for arm64 arch${normal}"
# echo -e "$ mkdir -p ~/git/${github_username}/${github_project}/tmp"
# mkdir -p "${HOME}/git/${github_username}/${github_project}/tmp"
# fi
# 
# # Navigate to working directory
# 
# echo -e "$ cd ~/git/${github_username}/${github_project}/tmp"
# cd "${HOME}/git/${github_username}/${github_project}/tmp" 2> /dev/null \
# || { echo -e "${redbold}> Failed to change directory, exiting${normal}\n"\
# ; exit 109; }
# 
# # get latest 1password amd64 deb package
# 
# echo -e "\n${cyanbold}Get latest 1password amd64 deb package${normal}"
# echo -e "$ wget -O 1password_${shortversion1p}_amd64.deb \
# https://downloads.1password.com/linux/debian/amd64/stable/1password-latest.deb"
# echo -e "\n"
# wget -O "1password_${shortversion1p}_amd64.deb" \
# https://downloads.1password.com/linux/debian/amd64/stable/1password-latest.deb
# 
# # TO-DO: Complete manual deb package build here
# # OR: Don't even make tmp folder; instead sig-check & install tarball
# 
# fi

# ###################### #
# END ARM64 ONLY SECTION #
# ###################### #

# Install firefox (on any arch)

if ! command -v firefox-devedition &> /dev/null; then

echo -e "\n${cyanbold}Install firefox-devedition${normal}"
echo -e "$ sudo apt update && sudo apt -y install firefox-devedition \
firefox-devedition-l10n-en-gb libpci3 libegl1\n"
sudo apt update && sudo apt -y install firefox-devedition \
firefox-devedition-l10n-en-gb libpci3 libegl1

if command -v wslinfo &> /dev/null; then
echo -e "\n${redbold}Restart needed to prevent firefox errors about \
org.a11y.Bus${normal}
Please run:

wsl.exe --shutdown"
fi

fi

# keep apt tidy

echo -e "\n${cyanbold}Make apt autoremove work properly${normal}"
echo -e "$ sudo apt-mark minimize-manual\n"
sudo apt-mark minimize-manual
echo -e "\n${cyanbold}Clean up apt packages${normal}"
echo -e "$ sudo apt autoremove --purge -y\n"
sudo apt autoremove --purge -y

# Log this latest `Config` operation and display runtime

echo -e "\n${bluebold}${local_filename} run at${normal}"
echo -e "> ${runtime}\n"
mkdir -p "${HOME}/git/${github_username}/${github_project}"
echo -e "FILE: ${local_filename} | EXEC-TIME: ${runtime}" \
>> "${HOME}/git/${github_username}/${github_project}/config-runs.log"

# Configure 1password-cli

echo -e "${cyanbold}Checking whether account registered in 1password-cli\
${normal}"
opclicheck1=$(op account list | grep -o "1password.com" 2> /dev/null)
if [[ "${opclicheck1}" != "1password.com" ]]; then
echo -e "${redbold}> No accounts registered in 1password-cli${normal}
> sign-in address = my.1password.com
>  email  address = p… .c…@gmail.com
>   For secret key:
>    Open https://my.1password.com/apps
>    …and click ‘Sign in manually’ button
> Next enter master password
> Finally enter TOTP from another 1password instance

RUN THIS NEXT:

eval \$(op account add --signin)
"
exit 112
else
echo -e "${greenbold}> Account(s) registered in 1password-cli${normal}\n"
echo -e "$ op account list\n"
op account list
echo -e "\n${cyanbold}Checking whether logged into 1password-cli${normal}"

if ! op account get &> /dev/null; then
echo -e "${redbold}> Not logged into 1password-cli${normal}\n
RUN THIS NEXT:\n
eval \$(op signin)\n"
exit 113
else
echo -e "${greenbold}> Logged into 1password-cli${normal}\n"
fi

fi

################################################################################
#
# Line wrap ruler
#
#   5   10   15   20   25   30   35   40   45   50   55   60   65   70   75   80
#
################################################################################

