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
git_filename="run_after_02-configure-repos-update-pkgs-Debian.sh"
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

debianarchivekeyfile="/usr/share/keyrings/debian-archive-trixie-automatic.asc"
debiansecuritykeyfile="/usr/share/keyrings/debian-archive-trixie-security-automatic.asc"
debianreleasekeyfile="/usr/share/keyrings/debian-archive-trixie-stable.asc"

# Get debian package keys

if [[ ! -s "${debianarchivekeyfile}"
   || ! -s "${debiansecuritykeyfile}"
   || ! -s "${debianreleasekeyfile}" ]]; then
echo -e "\n${cyanbold}Downloading debian signing keys${normal}"
fi

if [[ ! -s "${debianarchivekeyfile}" ]]; then
echo -e "$ \
curl -fsSL https://ftp-master.debian.org/keys/archive-key-13.asc | \
sudo tee \"${debianarchivekeyfile}\" 1> /dev/null"
curl -fsSL https://ftp-master.debian.org/keys/archive-key-13.asc | \
sudo tee "${debianarchivekeyfile}" 1> /dev/null
fi

if [[ ! -s "${debiansecuritykeyfile}" ]]; then
echo -e "$ \
curl -fsSL https://ftp-master.debian.org/keys/archive-key-13-security.asc | \
sudo tee \"${debiansecuritykeyfile}\" 1> /dev/null"
curl -fsSL https://ftp-master.debian.org/keys/archive-key-13-security.asc | \
sudo tee "${debiansecuritykeyfile}" 1> /dev/null
fi

if [[ ! -s "${debianreleasekeyfile}" ]]; then
echo -e "$ \
curl -fsSL https://ftp-master.debian.org/keys/release-13.asc | \
sudo tee \"${debianreleasekeyfile}\" 1> /dev/null"
curl -fsSL https://ftp-master.debian.org/keys/release-13.asc | \
sudo tee "${debianreleasekeyfile}" 1> /dev/null
fi

# Check debian package keys

echo -e "\n${cyanbold}Checking debian package signing keys${normal}"

# Manually find signing keys announcement when updating from Trixie (like this):
# https://lists.debian.org/debian-devel-announce/2025/04/msg00001.html
# (and https://ftp-master.debian.org/keys.html for release key)

expectedsha256trixiearchive="6f1d277429dd7ffedcc6f8688a7ad9a458859b1139ffa026d1eeaadcbffb0da7"
expectedsha256trixiesecurity="844c07d242db37f283afab9d5531270a0550841e90f9f1a9c3bd599722b808b7"
expectedsha256trixierelease="4d097bb93f83d731f475c5b92a0c2fcf108cfce1d4932792fca72d00b48d198b"

expectedkeytrixiearchive="04B54C3CDCA79751B16BC6B5225629DF75B188BD"
expectedkeytrixiesecurity="5E04A1E3223A19A20706E20F9904613D4CCE68C6"
expectedkeytrixierelease="41587F7DB8C774BCCF131416762F67A0B2C39DE4"

actualsha256trixiearchive=$(
sha256sum "${debianarchivekeyfile}" 2> /dev/null \
| awk '{print $1}'
)
actualsha256trixiesecurity=$(
sha256sum "${debiansecuritykeyfile}" 2> /dev/null \
| awk '{print $1}'
)
actualsha256trixierelease=$(
sha256sum "${debianreleasekeyfile}" 2> /dev/null \
| awk '{print $1}'
)

actualkeytrixiearchive=$(
gpg --no-default-keyring --with-colons --import-options show-only --import \
"${debianarchivekeyfile}" 2> /dev/null \
| awk -F':' '$1=="fpr"{print $10}' \
| head -n 1
)
actualkeytrixiesecurity=$(
gpg --no-default-keyring --with-colons --import-options show-only --import \
"${debiansecuritykeyfile}" 2> /dev/null \
| awk -F':' '$1=="fpr"{print $10}' \
| head -n 1
)
actualkeytrixierelease=$(
gpg --no-default-keyring --with-colons --import-options show-only --import \
"${debianreleasekeyfile}" 2> /dev/null \
| awk -F':' '$1=="fpr"{print $10}' \
| head -n 1
)

echo -e "\n 🔑 ${debianarchivekeyfile}"
echo -e " 🔤 ${expectedsha256trixiearchive}"
if [[ "${expectedsha256trixiearchive}" == "${actualsha256trixiearchive}" ]];
then
echo -e "${greenbold} ✅ The SHA256 hash matches${normal}"
else
echo -e "${redbold} ⛔ ${actualsha256trixiearchive}
 ⚠️ WARNING: unexpected SHA256 hash${normal}\n"
exit 101
fi
echo -e " 🔐 ${expectedkeytrixiearchive}"
if [[ "${expectedkeytrixiearchive}" == "${actualkeytrixiearchive}" ]];
then
echo -e "${greenbold} ✅ The key fingerprint matches${normal}"
else
echo -e "${redbold} ⛔ ${actualkeytrixiearchive}
 ⚠️ WARNING: unexpected fingerprint${normal}\n"
exit 102
fi

echo -e "\n 🔑 ${debiansecuritykeyfile}"
echo -e " 🔤 ${expectedsha256trixiesecurity}"
if [[ "${expectedsha256trixiesecurity}" == "${actualsha256trixiesecurity}" ]];
then
echo -e "${greenbold} ✅ The SHA256 hash matches${normal}"
else
echo -e "${redbold} ⛔ ${actualsha256trixiesecurity}
 ⚠️ WARNING: unexpected SHA256 hash${normal}\n"
exit 103
fi
echo -e " 🔐 ${expectedkeytrixiesecurity}"
if [[ "${expectedkeytrixiesecurity}" == "${actualkeytrixiesecurity}" ]];
then
echo -e "${greenbold} ✅ The key fingerprint matches${normal}"
else
echo -e "${redbold} ⛔ ${actualkeytrixiesecurity}
 ⚠️ WARNING: unexpected fingerprint${normal}\n"
exit 104
fi

echo -e "\n 🔑 ${debianreleasekeyfile}"
echo -e " 🔤 ${expectedsha256trixierelease}"
if [[ "${expectedsha256trixierelease}" == "${actualsha256trixierelease}" ]];
then
echo -e "${greenbold} ✅ The SHA256 hash matches${normal}"
else
echo -e "${redbold} ⛔ ${actualsha256trixierelease}
 ⚠️ WARNING: unexpected SHA256 hash${normal}\n"
exit 105
fi
echo -e " 🔐 ${expectedkeytrixierelease}"
if [[ "${expectedkeytrixierelease}" == "${actualkeytrixierelease}" ]];
then
echo -e "${greenbold} ✅ The key fingerprint matches${normal}"
else
echo -e "${redbold} ⛔ ${actualkeytrixierelease}
 ⚠️ WARNING: unexpected fingerprint${normal}\n"
exit 106
fi

# Add mozilla package key (on any arch)

mozillakeyfile="/usr/share/keyrings/mozilla-repo-signing-key.asc"
expectedmozillakey="35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3"

actualmozillakey=$(
gpg --no-default-keyring --with-colons --import-options show-only --import \
"${mozillakeyfile}" 2> /dev/null \
| awk -F':' '$1=="fpr"{print $10}' \
| head -n 1
)

if [[ "${actualmozillakey}" != "${expectedmozillakey}" ]];
then
echo -e "\n${cyanbold}Add Mozilla signing key${normal}"
echo -e "$ curl -fsSL https://packages.mozilla.org/apt/repo-signing-key.gpg \
| sudo tee \"${mozillakeyfile}\" 1> /dev/null"
curl -fsSL https://packages.mozilla.org/apt/repo-signing-key.gpg \
| sudo tee "${mozillakeyfile}" 1> /dev/null

actualmozillakey=$(
gpg --no-default-keyring --with-colons --import-options show-only --import \
"${mozillakeyfile}" 2> /dev/null \
| awk -F':' '$1=="fpr"{print $10}' \
| head -n 1
)

fi

echo -e "\n 🔑 ${mozillakeyfile}"
echo -e " 🔐 ${expectedmozillakey}"
if [[ "${expectedmozillakey}" == "${actualmozillakey}" ]];
then
echo -e "${greenbold} ✅ The key fingerprint matches${normal}"
else
echo -e "${redbold} ⛔ ${actualmozillakey}
 ⚠️ WARNING: unexpected fingerprint${normal}\n"
exit 107
fi

# Add nordvpn package key (on any arch)

nordvpnkeyfile="/usr/share/keyrings/nordvpn-repo-signing-key.asc"
expectednordvpnkey="BC5480EFEC5C081CE5BCFBE26B219E535C964CA1"

actualnordvpnkey=$(
gpg --no-default-keyring --with-colons --import-options show-only --import \
"${nordvpnkeyfile}" 2> /dev/null \
| awk -F':' '$1=="fpr"{print $10}' \
| head -n 1
)

if [[ "${actualnordvpnkey}" != "${expectednordvpnkey}" ]];
then
echo -e "\n${cyanbold}Add nordvpn signing key${normal}"
echo -e "$ curl -fsSL \
https://repo.nordvpn.com/deb/nordvpn/debian/dists/stable/public_key.asc \
| sudo tee \"${nordvpnkeyfile}\" 1> /dev/null"
curl -fsSL \
https://repo.nordvpn.com/deb/nordvpn/debian/dists/stable/public_key.asc \
| sudo tee "${nordvpnkeyfile}" 1> /dev/null

actualnordvpnkey=$(
gpg --no-default-keyring --with-colons --import-options show-only --import \
"${nordvpnkeyfile}" 2> /dev/null \
| awk -F':' '$1=="fpr"{print $10}' \
| head -n 1
)

fi

echo -e "\n 🔑 ${nordvpnkeyfile}"
echo -e " 🔐 ${expectednordvpnkey}"
if [[ "${expectednordvpnkey}" == "${actualnordvpnkey}" ]];
then
echo -e "${greenbold} ✅ The key fingerprint matches${normal}"
else
echo -e "${redbold} ⛔ ${actualnordvpnkey}
 ⚠️ WARNING: unexpected fingerprint${normal}\n"
exit 108
fi

# Add 1password package key (on amd64 arch only)

if [[ "${pkgarch}" == "amd64" ]]; then

# gpg not asc key to match built-in 1password config
# https://support.1password.com/install-linux/#debian-or-ubuntu
opkeyfile="/usr/share/keyrings/1password-archive-keyring.gpg"
expected1opkey="3FEF9748469ADBE15DA7CA80AC2D62742012EA22"

actualopkey=$(
gpg --no-default-keyring --with-colons --import-options show-only --import \
"${opkeyfile}" 2> /dev/null \
| awk -F':' '$1=="fpr"{print $10}' \
| head -n 1
)

if [[ "${actualopkey}" != "${expected1opkey}" ]];
then
echo -e "\n${cyanbold}Add 1password signing key${normal}"
echo -e "curl -fsSL https://downloads.1password.com/linux/keys/1password.asc \
| sudo gpg --yes --no-default-keyring --dearmor --output \"${opkeyfile}\""
curl -fsSL https://downloads.1password.com/linux/keys/1password.asc \
| sudo gpg --yes --no-default-keyring --dearmor --output "${opkeyfile}"

actualopkey=$(
gpg --no-default-keyring --with-colons --import-options show-only --import \
"${opkeyfile}" 2> /dev/null \
| awk -F':' '$1=="fpr"{print $10}' \
| head -n 1
)

fi

echo -e "\n 🔑 ${opkeyfile}"
echo -e " 🔐 ${expected1opkey}"
if [[ "${expected1opkey}" == "${actualopkey}" ]];
then
echo -e "${greenbold} ✅ The key fingerprint matches${normal}"
else
echo -e "${redbold} ⛔ ${actualopkey}
 ⚠️ WARNING: unexpected fingerprint${normal}\n"
exit 109
fi

fi

# modernise deb package config files

sourceslistfile="/etc/apt/sources.list"
pinprefsfile="/etc/apt/preferences.d/01-pin-prefs"
debiansecuritysourcesfile="/etc/apt/sources.list.d/01-trixie-security.sources"
debianstablesourcesfile="/etc/apt/sources.list.d/02-trixie-debian.sources"
debiansidsourcesfile="/etc/apt/sources.list.d/99-sid-debian.sources"

if [[ -f "${sourceslistfile}"
   || ! -f "${pinprefsfile}"
   || ! -f "${debiansecuritysourcesfile}"
   || ! -f "${debianstablesourcesfile}"
   || ! -f "${debiansidsourcesfile}" ]]; then
echo -e "\n${cyanbold}Updating package sources to deb822 format${normal}"
fi

# Remove legacy single sources file

if [[ -f "${sourceslistfile}" ]]; then
echo -e "$ sudo rm \"${sourceslistfile}\""
sudo rm "${sourceslistfile}"
fi

# Remove legacy apt keys

legacy_key_file_count=$(
sudo find /etc/apt/trusted.gpg.d/ -type f 2>/dev/null \
| wc -l
)
if [[ "${legacy_key_file_count}" -gt 0 ]]; then
echo -e "\n${bluebold}Found ${legacy_key_file_count} legacy key(s)${normal}"
echo -e "$ sudo find /etc/apt/trusted.gpg.d/ -type f -delete"
sudo find /etc/apt/trusted.gpg.d/ -type f -delete
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

PIN_PREFS="\
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
Pin: origin \"downloads.1password.com\"
Pin-Priority: 970

Explanation: Prioritise mozilla repo just less than Trixie/Stable
Package: *
Pin: origin \"packages.mozilla.org\"
Pin-Priority: 970

Explanation: Prioritise nordvpn repo just less than Trixie/Stable
Package: *
Pin: origin \"repo.nordvpn.com\"
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
"

if ! cmp -s <(echo "${PIN_PREFS}") "${pinprefsfile}";
then
echo -e "\n${bluebold}Create/update ${pinprefsfile}${normal}"
echo -e "$ echo \"\${PIN_PREFS}\" | sudo tee \"${pinprefsfile}\" 1> /dev/null"
echo "${PIN_PREFS}" | sudo tee "${pinprefsfile}" 1> /dev/null
fi

SECURITY_SOURCES="\
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
Signed-By: ${debiansecuritykeyfile}
"

if ! cmp -s <(echo "${SECURITY_SOURCES}") "${debiansecuritysourcesfile}";
then
echo -e "\n${bluebold}Create/update ${debiansecuritysourcesfile}${normal}"
echo -e "$ echo \"\${SECURITY_SOURCES}\" | sudo tee \"${debiansecuritysourcesfile}\" 1> /dev/null"
echo "${SECURITY_SOURCES}" | sudo tee "${debiansecuritysourcesfile}" 1> /dev/null
fi

STABLE_SOURCES="\
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
Signed-By: ${debianarchivekeyfile}
"

if ! cmp -s <(echo "${STABLE_SOURCES}") "${debianstablesourcesfile}";
then
echo -e "\n${bluebold}Create/update ${debianstablesourcesfile}${normal}"
echo -e "$ echo \"\${STABLE_SOURCES}\" | sudo tee \"${debianstablesourcesfile}\" 1> /dev/null"
echo "${STABLE_SOURCES}" | sudo tee "${debianstablesourcesfile}" 1> /dev/null
fi

SID_SOURCES="\
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
Signed-By: ${debianarchivekeyfile}
"

if ! cmp -s <(echo "${SID_SOURCES}") "${debiansidsourcesfile}";
then
echo -e "\n${bluebold}Create/update ${debiansidsourcesfile}${normal}"
echo -e "$ echo \"\${SID_SOURCES}\" | sudo tee \"${debiansidsourcesfile}\" 1> /dev/null"
echo "${SID_SOURCES}" | sudo tee "${debiansidsourcesfile}" 1> /dev/null
fi

# Install mozilla deb repo (on any arch)

mozillasourcesfile="/etc/apt/sources.list.d/03-mozilla.sources"
MOZILLA_SOURCES="\
# Mozilla apt package repository
Types: deb
URIs: https://packages.mozilla.org/apt
Suites: mozilla
Components: main
Architectures: ${pkgarch}
Signed-By: ${mozillakeyfile}
"

if ! cmp -s <(echo "${MOZILLA_SOURCES}") "${mozillasourcesfile}";
then
echo -e "\n${bluebold}Create/update ${mozillasourcesfile}${normal}"
echo -e "$ echo \"\${MOZILLA_SOURCES}\" | sudo tee \"${mozillasourcesfile}\" 1> /dev/null"
echo "${MOZILLA_SOURCES}" | sudo tee "${mozillasourcesfile}" 1> /dev/null
fi

# Install nordvpn deb repo (on any arch)

nordvpnsourcesfile="/etc/apt/sources.list.d/04-nordvpn.sources"
NORDVPN_SOURCES="\
# Nordvpn apt package repository
Types: deb
URIs: https://repo.nordvpn.com/deb/nordvpn/debian/
Suites: stable
Components: main
Architectures: ${pkgarch}
Signed-By: ${nordvpnkeyfile}
"

if ! cmp -s <(echo "${NORDVPN_SOURCES}") "${nordvpnsourcesfile}";
then
echo -e "\n${bluebold}Create/update ${nordvpnsourcesfile}${normal}"
echo -e "$ echo \"\${NORDVPN_SOURCES}\" | sudo tee \"${nordvpnsourcesfile}\" 1> /dev/null"
echo "${NORDVPN_SOURCES}" | sudo tee "${nordvpnsourcesfile}" 1> /dev/null
fi

# Install 1password deb repo (on amd64 arch only)
if [[ "${pkgarch}" == "amd64" ]]; then

opsourcesfile="/etc/apt/sources.list.d/1password.sources"
OP_SOURCES="\
# /etc/apt/sources.list.d/1password.sources
# 1password debian repository
Types: deb
URIs: https://downloads.1password.com/linux/debian/amd64
Suites: stable
Components: main
Architectures: amd64
Signed-By: ${opkeyfile}
"

if ! cmp -s <(echo "${OP_SOURCES}") "${opsourcesfile}";
then
echo -e "\n${bluebold}Create/update ${opsourcesfile}${normal}"
echo -e "$ echo \"\${OP_SOURCES}\" | sudo tee \"${opsourcesfile}\" 1> /dev/null"
echo "${OP_SOURCES}" | sudo tee "${opsourcesfile}" 1> /dev/null
fi

# Configure debsig policy for repos that support it
# (only 1Password so can't be turned on globally)

onepname="1password"
onepid=$(
gpg --list-packets /usr/share/keyrings/1password-archive-keyring.gpg \
| awk '$1=="keyid:"{print$2}' \
| head -n 1
)

if [[ ! -s "/etc/debsig/policies/${onepid}/${onepname}.pol"
   || ! -s "/usr/share/debsig/keyrings/${onepid}/debsig.gpg" ]]; then
echo -e "\n${bluebold}Set debsig policy for ${onepname}${normal}"
echo -e "> Create /usr/share/debsig/keyrings/${onepid}/debsig.gpg"

# Catch errors with 1password key
if [[ -z "${onepid}" ]]; then exit 110; fi
# Create folder with key fingerprint
sudo mkdir -p "/etc/debsig/policies/${onepid}"

opdebsigfile="/etc/debsig/policies/${onepid}/${onepname}.pol"
OP_DEBSIG="\
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
</Policy>
"

if [[ ! -s "${opdebsigfile}" ]];
then
echo -e "\n${bluebold}Create ${opdebsigfile}${normal}"
echo -e "$ echo \"\${OP_DEBSIG}\" | sudo tee \"${opdebsigfile}\" 1> /dev/null"
echo "${OP_DEBSIG}" | sudo tee "${opdebsigfile}" 1> /dev/null
sudo mkdir -p "/usr/share/debsig/keyrings/${onepid}"
echo -e "> Create /usr/share/debsig/keyrings/${onepid}/debsig.gpg"
sudo cp /usr/share/keyrings/1password-archive-keyring.gpg \
"/usr/share/debsig/keyrings/${onepid}/debsig.gpg"
fi

# Close checks for debsig files
fi

# Close check for amd64 arch only
fi

# Update apt if last `sudo apt update` more than one hour ago
# touch the lock file to capture timestamp of updates with no file changes

now="$(date +%s)"
last_update="$(
find /var/lib/apt/lists/ -maxdepth 1 -type f -printf '%Ts\n' 2>/dev/null |
sort -nr | head -n 1
)"
if (( now - ${last_update:-0} > 3600 )); then
echo -e "\n${cyanbold}Update apt${normal}"
echo -e "$ sudo apt update\n"
LOCKFILE="/var/lib/apt/lists/lock"
sudo apt update && sudo flock -n "${LOCKFILE}" touch "${LOCKFILE}"
fi

# Check for packages with one-off post-install steps BEFORE apt upgrade

# Firefox comes from chezmoi template; message to show if/when it is installed
firefoxnotinstalled="0"
if ! command -v firefox-devedition &> /dev/null; then
(( firefoxnotinstalled += 1 ))
fi

# nordvpn comes from chezmoi template; config required to use this software
nordvpnconfigneeded="0"
if ! command -v nordvpn &> /dev/null; then
(( nordvpnconfigneeded += 1 ))
fi

# On WSL only, install dummy packages before any other apt install
if [[ -d "/run/WSL" ]]; then

# Define function to build and install a dummy package

create_dummy_pkg() {
local TARGET_PKG="$1"
local DUMMY_PKG="${TARGET_PKG}-dummy"
local TMP_DIR="${HOME}/git/${github_username}/${github_project}/tmp"

DUMMY_REQD="$(dpkg -l "${DUMMY_PKG}" 2> /dev/null | grep -oP "^ii\\s+${DUMMY_PKG}")"
DPKG_ERROR=$?

if [ -z "${DUMMY_REQD}" ] || [ "${DPKG_ERROR}" -ne 0 ]; then
echo -e "\n${cyanbold}Installing ${DUMMY_PKG} package${normal}"

echo -e "$ mkdir -p ${TMP_DIR}"
mkdir -p "${TMP_DIR}"

# equivs-build always outputs package to current working directory
echo -e "$ cd ${TMP_DIR}"
cd "${TMP_DIR}" 2> /dev/null \
|| { echo -e "  ${redbold}Failed to change directory, exiting${normal}"\
; exit 111; }

DUMMY_PAYLOAD="\
Section: misc
Priority: optional
Standards-Version: 3.9.2

Package: ${DUMMY_PKG}
Version: 1.0
Provides: ${TARGET_PKG}
Conflicts: ${TARGET_PKG}
Architecture: all
Description: Dependency resolving dummy pkg for deliberately missing ${TARGET_PKG}
"
# Show payload variable without expansion here (with backslash escapes)
echo -e "$ printf \"%s\" \"\${DUMMY_PAYLOAD}\" | sudo tee ${DUMMY_PKG} > /dev/null"
printf "%s" "${DUMMY_PAYLOAD}" | tee "${DUMMY_PKG}" > /dev/null
echo -e "$ cat ${DUMMY_PKG}\n"
cat "${DUMMY_PKG}"

echo -e "\n$ equivs-build ${DUMMY_PKG}\n"
equivs-build "${DUMMY_PKG}"

echo -e "\n$ sudo dpkg -i ${DUMMY_PKG}_1.0_all.deb\n"
sudo dpkg -i "${DUMMY_PKG}_1.0_all.deb"

echo -e "$ cd ~/git/${github_username}/${github_project}"
cd "${HOME}/git/${github_username}/${github_project}" 2> /dev/null \
|| { echo -e "  ${redbold}Failed to change directory, exiting${normal}"\
; exit 112; }

echo -e "$ rm -rf ${TMP_DIR}"
rm -rf "${TMP_DIR}"

fi
}

# Create dummy packages
# (Don't need GUI tools for network, power, or bluetooth in WSL2)
# equivs dependency was installed by script 01

if ! command -v equivs-build &> /dev/null; then
echo -e "${redbold}> Missing equivs package dependency, exiting${normal}"
exit 113
else
create_dummy_pkg "plasma-nm"
create_dummy_pkg "powerdevil"
create_dummy_pkg "bluedevil"
fi

# End WSL only dummy packages section
fi

# PACKAGES either from chezmoi template or from fixed bootstrap fallback list
aptpkglistfile="${HOME}/.config/scripts/00-apt-pkg.list"
if [[ -s "${aptpkglistfile}" ]]; then
# Load PACKAGES from chezmoi template
mapfile -t PACKAGES < "${aptpkglistfile}"
else
# Construct PACKAGES bootstrap fallback list
# Start with min pkg list to install all (essential|priority|important) deb pkgs
EPI_PKGS=$(
apt-cache dumpavail |
awk '/^Package:/ {pkg=$2} /^Essential: yes/ || /^Priority: required/ || /^Priority: important/ {print pkg}' |
sort -u
)
# Remove from list any pkg that is a (Depends|PreDepends) of any other
mapfile -t PACKAGES < <(
comm -23 \
<(printf '%s\n' "$EPI_PKGS") \
<(printf '%s\n' "$EPI_PKGS" | xargs -r apt-cache depends 2>/dev/null | awk \
'/^[[:space:]]*\|?(Depends|PreDepends):/ {print $NF}' | tr -d '<>' | sort -u)
)
# Add a minimum list of extra packages to the bootstrap fallback list
# Include one named terminal emulator here (qterminal) to prevent auto-install
# of something unwanted by x-terminal-emulator virtual package later.
PACKAGES+=(
sudo
ca-certificates
curl
wget
gpg
cosign
debsigs
equivs
locales
keyboard-configuration
console-setup
aptitude
qterminal
)
# Close the chezmoi template file or bootstrap fallback list choice
fi

# Add 1password on amd64 arch only
if [[ "${pkgarch}" == "amd64" ]]; then
PACKAGES+=(
1password
1password-cli
)
fi

# mark manual so apt upgrade can do apt install too

echo -e "\n${cyanbold}Keep apt tidy and apt-mark manual${normal}"

# warn about installed packages not in chezmoi config

ignorepkgs=(
1password
1password-cli
chezmoi
bluedevil-dummy
plasma-nm-dummy
powerdevil-dummy
)
pkgwarning=$(
comm -23 <(apt-mark showmanual | sort) <(printf '%s\n' "${PACKAGES[@]}" |
sort -u) | comm -23 - <(printf '%s\n' "${ignorepkgs[@]}" | sort -u)
)
if [[ -n "$pkgwarning" ]]; then
echo -e "\n${redbold}WARNING: Unexpected Debian packages installed${normal}"
echo -e "${pkgwarning}"
fi

if command -v aptitude &> /dev/null; then
echo -e "> Aggressive markauto"
echo -e "$ sudo aptitude markauto '~i (~RDepends:~i | ~RPreDepends:~i)'"
sudo aptitude markauto '~i (~RDepends:~i | ~RPreDepends:~i)'
fi

# warn about duplicates in chezmoi config

# ca-certificates is a dependency of nordvpn
# curl is a dependency of 1password
# sudo is an indirect dependency of plasma-desktop
ignoreduplicates=(
ca-certificates
curl
sudo
)
pkgduplicates=$(
comm -23 <(printf '%s\n' "${PACKAGES[@]}" | sort -u) <(apt-mark showmanual |
sort) | comm -23 - <(printf '%s\n' "${ignoreduplicates[@]}" | sort -u)
)
if [[ -n "$pkgduplicates" ]]; then
echo -e "\n${redbold}WARNING: Unexpected Debian packages installed${normal}"
echo -e "${pkgduplicates}"
fi

echo -e "\n> Combine apt install into apt upgrade with apt-mark manual"
echo -e "$ sudo apt-mark manual ${PACKAGES[*]}\n"
printf '%s\n' "${PACKAGES[@]}" | xargs sudo apt-mark manual

mapfile -t RC_PKGS < <(dpkg -l | awk '/^rc/ {print $2}')

if (( ${#RC_PKGS[@]} > 0 )); then
echo -e "\n> Purge residual configs"
echo -e "$ sudo apt-get purge -y ${RC_PKGS[*]}"
sudo apt-get purge -y "${RC_PKGS[@]}"
fi

echo -e "\n> Remove and purge not needed packages"
echo -e "$ sudo apt autoremove --purge -y\n"
sudo apt autoremove --purge -y

echo -e "\n> Remove obsolete deb package local copies"
echo -e "$ sudo apt-get autoclean\n"
sudo apt-get autoclean

# apt upgrade if needed

count_upgrade_pkgs=$(apt-get -s upgrade | grep -c '^Inst ')
if (( count_upgrade_pkgs > 0 )); then
echo -e "\n${cyanbold}Run apt upgrade${normal}"
echo -e "$ sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y\n"
sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y
fi

# Check for packages with one-off post-install steps AFTER apt upgrade

# Firefox comes from chezmoi template; message to show if/when it is installed
if command -v firefox-devedition &> /dev/null; then
(( firefoxnotinstalled += 2 ))
fi

# nordvpn comes from chezmoi template; config required to use this software
if command -v nordvpn &> /dev/null; then
(( nordvpnconfigneeded += 2 ))
fi

# Do one-off post-install checks where required

if (( firefoxnotinstalled == 3 )) && [[ -d "/run/WSL" ]]; then
echo -e "
${redbold}Restart needed to prevent firefox errors about org.a11y.Bus${normal}
Please run:

wsl.exe --shutdown"
fi

if (( nordvpnconfigneeded == 3 )); then
echo -e "\n${cyanbold}Configuring nordvpn${normal}"
echo -e "$ sudo usermod -aG nordvpn \"${USER}\""
sudo usermod -aG nordvpn "${USER}"
echo -e "$ xdg-mime default nordvpn.desktop x-scheme-handler/nordvpn"
xdg-mime default nordvpn.desktop x-scheme-handler/nordvpn
echo -e "
${redbold}Restart needed for nordvpn to work${normal}
Please run one of:
sudo reboot
OR
wsl.exe --shutdown"
fi

if [ -s "/usr/share/applications/qterminal-drop.desktop" ]; then
echo -e "\n${cyanbold}Remove QTerminal drop down launcher${normal}"
echo -e "$ sudo rm /usr/share/applications/qterminal-drop.desktop"
sudo rm /usr/share/applications/qterminal-drop.desktop
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

# 1password debian packages available on amd64 only
if [[ "${pkgarch}" == "amd64" ]]; then

echo -e "\n${cyanbold}Installed 1password debian package versions${normal}"

installedversion1p=$(
apt-cache policy 1password | grep Installed | awk -F ': ' '{print $2}'
)
installedver1pcli=$(
apt-cache policy 1password-cli | grep Installed | awk -F ': ' '{print $2}'
)
echo -e "> ${installedversion1p} = 1password"
echo -e "> ${installedver1pcli} = 1password-cli"

# Close amd64 arch choice, latest version aready managed by apt
fi

# Install 1password from tarball on arm64 only
# if [[ "${pkgarch}" == "arm64" ]]; then
# TO-DO: Need to setup hardware before can work on this arch
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
# ; exit 114; }
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

# Close arm64 arch choice, latest version aready managed by apt
# fi

# Install / Update chezmoi (on any arch)

chezmoi_latestver=$(
curl -ILsS -w "%{url_effective}" -o /dev/null \
"https://github.com/twpayne/chezmoi/releases/latest" \
| sed 's|.*/v\?||'
)
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
\"${tmp_dir}/${chk_file}\"\n"
if cosign verify-blob \
    --key "${tmp_dir}/chezmoi_cosign.pub" \
    --signature "${tmp_dir}/${sig_file}" \
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
        exit 114
    # Close sha256sum check
    fi
else
    echo -e "${redbold} ⚠️ WARNING: Signature verification failed${normal}\n"
    exit 115
# Close cosign check
fi
# Close chezmoi not latest version check
fi

git_dir="${HOME}/git/${github_username}/${github_project}"
# If .git directory does not exist (will need chezmoi init)
if [[ ! -d "${git_dir}/.git" ]]; then
# If config-runs.log file exists here
if [[ -s "${git_dir}/config-runs.log" ]]; then
# Temporarily store config-runs.log up one level
echo -e "\n> move config-runs.log"
echo -e "$ mv ${git_dir}/config-runs.log ~/git/${github_username}/config-runs.log"
mv "${git_dir}/config-runs.log" "${HOME}/git/${github_username}/config-runs.log"
else echo ""
fi
# If one or more file exists in $git_dir
if [[ -n $(find "${git_dir}" -mindepth 1 -maxdepth 1 -print -quit  2>/dev/null) ]]
then
# Clear whole repo location so a fresh git clone will work
echo -e "$ find ${git_dir} -mindepth 1 -delete"
find "${git_dir}" -mindepth 1 -delete
fi
# chezmoi initial config
echo -e "\n$ chezmoi init https://github.com/${github_username}/\
${github_project}.git --source ~/git/${github_username}/${github_project}\n"
chezmoi init "https://github.com/${github_username}/${github_project}\
.git" --source "${git_dir}"
# If config-runs.log file exists here
if [[ -s "${HOME}/git/${github_username}/config-runs.log" ]]; then
# Move config-runs.log back into project folder
echo -e "> move config-runs.log"
echo -e "$ mv ~/git/${github_username}/config-runs.log ${git_dir}/config-runs.log"
mv "${HOME}/git/${github_username}/config-runs.log" "${git_dir}/config-runs.log"
fi
# All chezmoi init tasks complete
echo -e "\n${greenbold} ✅ chezmoi init complete${normal}"
# Logic branch where .git for chezmoi dotfiles already exists
else
echo -e "${greenbold}> chezmoi init has already occurred${normal}"
# Close need chezmoi init check
fi

# Replicate the fully evaluated script to your target directory

THIS_SCRIPT="${HOME}/git/${github_username}/${github_project}/HOME/dot_config/scripts/${git_filename}"
if [[ -s "${THIS_SCRIPT}" ]]; then
echo -e "\n${cyanbold}Save a copy of ‘${local_filename}’${normal}"
echo -e "\
$ install -CDm 755 \"\${THIS_SCRIPT}\" ~/.config/scripts/${local_filename}"
install -CDm 755 "${THIS_SCRIPT}" "${HOME}/.config/scripts/${local_filename}"
fi

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

