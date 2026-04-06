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
op_token_in_ram_path="/dev/shm/op_session_token_${USER}"

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

expectedsha256trixiearchive="6f1d277429dd7ffedcc6f8688a7ad9a458859b1139ffa026d1eeaadcbffb0da7"
expectedsha256trixiesecurity="844c07d242db37f283afab9d5531270a0550841e90f9f1a9c3bd599722b808b7"
expectedsha256trixierelease="4d097bb93f83d731f475c5b92a0c2fcf108cfce1d4932792fca72d00b48d198b"

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

if [[ -d "/run/WSL" ]]; then
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

if [[ ! -f /etc/apt/preferences.d/01-pin-prefs ]] || \
! cmp -s <(echo -e "${PIN_PREFS}") /etc/apt/preferences.d/01-pin-prefs;
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

# Catch errors with 1password key
if [[ -z "${onepid}" ]]; then exit 109; fi
# Create folder with key fingerprint
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

count_upgrade_pkgs=$(apt list --upgradable 2> /dev/null | grep -c -v "^Listing")
# Yes, apt list format is not stable but confident it will always be 1 line/pkg!
# Thus don't want to use any alternative above!
if (( count_upgrade_pkgs > 0 )); then
echo -e "\n${cyanbold}Run apt upgrade${normal}"
echo -e "$ sudo apt upgrade -y\n"
sudo apt upgrade -y
fi

# Check for packages and install if necessary
# Before network test, because network test uses wget
# Include one named terminal emulator here to prevent auto-install of other
# terminal emulator applications by x-terminal-emulator virtual package later
# Foot is a high-performance, wayland first/only, terminal emulator
# Include firefox and three supporting packages

firefoxnotinstalled="0"
if ! command -v firefox-devedition &> /dev/null; then
firefoxnotinstalled="1"
fi

PACKAGES=(
curl
wget
git
gh
gpg
cosign
debsigs
equivs
foot
firefox-devedition
firefox-devedition-l10n-en-gb
libpci3
libegl1
)
DPKG_OUTPUT=$(dpkg-query -W -f='${db:Status-Status} ${Package}\n' \
"${PACKAGES[@]}" 2> /dev/null)
DPKG_ERROR=$?
if [[ "${DPKG_ERROR}" -eq 0 ]]; then
APT_REQD=$(echo "${DPKG_OUTPUT}" | awk '$1 != "installed" {print $2}')
fi

if [[ -n "${APT_REQD}" || "${DPKG_ERROR}" -ne 0 ]]; then
echo -e "\n${cyanbold}Installing packages${normal}"
echo -e "$ sudo apt install -y ${PACKAGES[*]}"
sudo apt install -y "${PACKAGES[@]}"
fi

if (( firefoxnotinstalled == 1 )) && [[ -d "/run/WSL" ]]; then
echo -e "\n${redbold}Restart needed to prevent firefox errors about \
org.a11y.Bus${normal}
Please run:

wsl.exe --shutdown"
fi

# Get latest 1password versions

onepasswordlinuxreleases=$(
curl -fsS "https://releases.1password.com/linux/stable/index.xml" | awk -v RS="<item>" '
{
    # Set default values for each variable to prevent data carry-over
    version_str = ""; array_version = "0.0.0"; pubdate = ""
    # Drop the XML preamble before the first <item> tag
    if (NR == 1) next;
    # Drop closing </item> tags and anything following them
    sub(/<\/item>.*/, "")
    # Match link tags then strip 6 char opening tag & 7 char closing tag
    match($0, /<link>[^<]+<\/link>/)
    if (RSTART > 0) {
        version_str = substr($0, RSTART+6, RLENGTH-13)
        # Drop the leading URL
        sub(/https:\/\/releases\.1password\.com\/linux\/stable\//, "", version_str)
        # Substitute all remaining / with nothing
        gsub(/\//, "", version_str)
        # Split version_str into 3-part array "v" at the period character
        split(version_str, v, ".")
        # Force integer conversion
        array_version = (v[1]+0) "." (v[2]+0) "." (v[3]+0)
    }
    # Match pubDate tags then strip 9 char opening tag & 19 char closing tag
    match($0, /<pubDate>[^<]+<\/pubDate>/)
    if (RSTART > 0) {
        raw_pubdate = substr($0, RSTART+9, RLENGTH-19)
        # Drop last 15 char (time & timezone)
        pubdate = substr(raw_pubdate, 1, length(raw_pubdate) - 15)
        # format date (remove comma, replace space with hyphen)
        gsub(/,/, "", pubdate); gsub(/ /, "-", pubdate)
    } else {
        pubdate = ""
    }
    # Final Output
    if (array_version != "0.0.0") {
        print array_version " | " pubdate
    }
}'
)
latestonepasswordlinuxrelease=$(
echo "${onepasswordlinuxreleases}" \
| sort -t'.' -k1,1nr -k2,2nr -k3,3nr \
| head -n 1
)
onepasswordlinuxlatestversion=$(
echo "${latestonepasswordlinuxrelease}" \
| cut -d '|' -f1 | xargs
)
onepasswordlinuxreleasedate=$(
echo "${latestonepasswordlinuxrelease}" \
| cut -d '|' -f2 | xargs
)
echo -e "\n${cyanbold}Latest release info for 1password linux stable${normal}"
echo -e "> See https://releases.1password.com/linux/stable/"
echo -e "> ${onepasswordlinuxlatestversion}"
echo -e "> ${onepasswordlinuxreleasedate}"

opclireleases=$(
curl -fsS "https://releases.1password.com/developers/cli/index.xml" | awk -v RS="<item>" '
{
    # Set default values for each variable to prevent data carry-over
    version_str = ""; array_version = "0.0.0"; pubdate = ""
    # Drop the XML preamble before the first <item> tag
    if (NR == 1) next;
    # Drop closing </item> tags and anything following them
    sub(/<\/item>.*/, "")
    # Match link tags then strip 6 char opening tag & 7 char closing tag
    match($0, /<link>[^<]+<\/link>/)
    if (RSTART > 0) {
        version_str = substr($0, RSTART+6, RLENGTH-13)
        # Drop the leading URL
        sub(/https:\/\/releases\.1password\.com\/developers\/cli\//, "", version_str)
        # Substitute all remaining / with nothing
        gsub(/\//, "", version_str)
        # Split version_str into 3-part array "v" at the period character
        split(version_str, v, ".")
        # Force integer conversion
        array_version = (v[1]+0) "." (v[2]+0) "." (v[3]+0)
    }
    # Match pubDate tags then strip 9 char opening tag & 19 char closing tag
    match($0, /<pubDate>[^<]+<\/pubDate>/)
    if (RSTART > 0) {
        raw_pubdate = substr($0, RSTART+9, RLENGTH-19)
        # Drop last 15 char (time & timezone)
        pubdate = substr(raw_pubdate, 1, length(raw_pubdate) - 15)
        # format date (remove comma, replace space with hyphen)
        gsub(/,/, "", pubdate); gsub(/ /, "-", pubdate)
    } else {
        pubdate = ""
    }
    # Final Output
    if (array_version != "0.0.0") {
        print array_version " | " pubdate
    }
}'
)
latestopclirelease=$(
echo "${opclireleases}" \
| sort -t'.' -k1,1nr -k2,2nr -k3,3nr \
| head -n 1
)
opclilatestversion=$(
echo "${latestopclirelease}" \
| cut -d '|' -f1 | xargs
)
opclireleasedate=$(
echo "${latestopclirelease}" \
| cut -d '|' -f2 | xargs
)
echo -e "\n${cyanbold}Latest release info for 1password-cli${normal}"
echo -e "> See https://releases.1password.com/developers/cli/"
echo -e "> ${opclilatestversion}"
echo -e "> ${opclireleasedate}"

# ################## #
# ON AMD64 ARCH ONLY #
# ################## #
if [[ "${pkgarch}" == "amd64" ]]; then

# debian packages available on amd64 only

echo -e "\n${cyanbold}Installed 1password debian package versions${normal}"

installedversion1p=$(
apt-cache policy 1password | grep Installed | awk -F ': ' '{print $2}'
)
installedver1pcli=$(
apt-cache policy 1password-cli | grep Installed | awk -F ': ' '{print $2}'
)
echo -e "> ${installedversion1p:-${bluebold}(none)${normal}} = 1password"
echo -e "> ${installedver1pcli:-${bluebold}(none)${normal}} = 1password-cli"

# Install 1password

echo -e "\n${cyanbold}Checking if 1password is upgradable${normal}"

opguiinstallcheck=$(
dpkg -s 1password 2> /dev/null | grep "Package: 1password"
)
opcliinstallcheck=$(
dpkg -s 1password-cli 2> /dev/null | grep "Package: 1password-cli"
)
opupdatecheck=$(
apt list --upgradable 2>&1 \
| grep -vE "Use with caution in scripts|Listing" \
| grep -o "1password" \
| head -n 1
)
# Yes, apt list format is not stable but confident it will always name upgrades!
# Thus don't want to use any alternative above!
op_needs_signin="0"
if [[ "${opupdatecheck}" == "1password"
   || "${opguiinstallcheck}" != "Package: 1password"
   || "${opcliinstallcheck}" != "Package: 1password-cli" ]]; then
op_needs_signin="1"
echo -e "\n${cyanbold}Installing 1password${normal}"
echo -e "$ sudo apt -y install 1password 1password-cli\n"
sudo apt -y install 1password 1password-cli
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
# ; exit 110; }
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

# Install / Update chezmoi (on any arch)

chezmoi_release_url="https://github.com/twpayne/chezmoi/releases/latest"
chezmoi_json=$(
curl -fsSL -H "Accept: application/json" "${chezmoi_release_url}"
)
chezmoi_tag=$(
printf '%s\n' "${chezmoi_json}" \
| tr -s '\n' ' ' \
| sed 's/.*"tag_name":"//' \
| sed 's/".*//'
)
chezmoi_latestver=${chezmoi_tag#v}
chezmoi_installedver=$(
chezmoi --version 2> /dev/null | awk '{print $3}' | tr -d 'v,'
)
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
sig_file="${chk_file}.sig"
pub_file="chezmoi_cosign.pub"
base_url="https://github.com/twpayne/chezmoi/releases/download/v${chezmoi_latestver}"

# Ensure availability of working folder for deb package installation
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
--signature \"${tmp_dir}/${sig_file}\" \
\"${tmp_dir}/${chk_file}\""
if cosign verify-blob \
    --key "${tmp_dir}/chezmoi_cosign.pub" \
    --signature "${tmp_dir}/${sig_file}" \
    "${tmp_dir}/${chk_file}" &> /dev/null; then
    
    echo -e "${greenbold} ✅ Checksum file signature verified${normal}"
    echo -e "> Verifying deb package integrity"
    
    # Check the sha256 of the deb pkg
    if ( cd "${tmp_dir}" && sha256sum --ignore-missing -c --status "${chk_file}" ); then
        echo -e "${greenbold} ✅ deb package integrity verified${normal}"
        echo -e "$ sudo apt install -y ${tmp_dir}/${deb_file}"
        sudo apt install -y "${tmp_dir}/${deb_file}"
        echo -e "$ chezmoi init https://github.com/${github_username}/${github_project}.git"
        chezmoi init "https://github.com/${github_username}/${github_project}.git"
    else
        echo -e "${redbold} ⚠️ WARNING: deb package checksum failed${normal}\n"
        exit 110
    # Close sha256sum check
    fi
else
    echo -e "${redbold} ⚠️ WARNING: Signature verification failed${normal}\n"
    exit 111
# Close cosign check
fi

# Clean up the working folder
rm -rf "${tmp_dir}"

else
echo -e "${greenbold}> chezmoi is already up-to-date${normal}"

# Close check whether chezmoi needed installing / updating
fi

# keep apt tidy

echo -e "\n${cyanbold}Make apt autoremove work properly${normal}"
echo -e "$ sudo apt-mark minimize-manual\n"
sudo apt-mark minimize-manual
echo -e "\n${cyanbold}Clean up apt packages${normal}"
echo -e "$ sudo apt autoremove --purge -y\n"
sudo apt autoremove --purge -y

# Check whether 1password-cli installed or updated
if (( op_needs_signin == 1 )); then

# Check whether signed into 1password-cli
if ! op whoami &> /dev/null; then

echo -e "\n${cyanbold}Manage 1password-cli authentication (op signin)${normal}"

# Check if the token file exists
if [[ -f "${op_token_in_ram_path}" ]]
    
    # Branch where prior op session token exists
    then
    # Read the token and export it for this script's session
    OP_SESSION_my=$(cat "${op_token_in_ram_path}")
    export OP_SESSION_my
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
            exit 201
            
        # Close check for errors in generating new session token
        fi
        
        # Branch where you declined to create a new valid token for 1password-cli
        else
        echo -e "${redbold}> You chose no. All secrets injection from 1password will be skipped for this chezmoi run${normal}"
        
    # Close [Y/n] choice whether to sign into 1password
    fi
# Close check whether you have a valid 1password-cli session
fi

# Close check whether signed into 1password-cli
fi
# Close check whether 1password-cli installed or updated
fi

# Replicate the fully evaluated script to your target directory

echo -e "\n${cyanbold}Save a copy of  ‘${local_filename}’${normal}"
mkdir -p "${HOME}/.config/scripts"
echo -e "$ cp \"\$0\" \"~/.config/scripts/${local_filename}\""
cp "$0" "${HOME}/.config/scripts/${local_filename}"

# Log this latest `Config` operation and display runtime

echo -e "\n${bluebold}${local_filename} run at${normal}"
echo -e "> ${runtime}\n"
mkdir -p "${HOME}/git/${github_username}/${github_project}" && \
echo -e "FILE: ${local_filename} | EXEC-TIME: ${runtime}" \
>> "${HOME}/git/${github_username}/${github_project}/config-runs.log"

################################################################################
#
# Line wrap ruler
#
#   5   10   15   20   25   30   35   40   45   50   55   60   65   70   75   80
#
################################################################################

