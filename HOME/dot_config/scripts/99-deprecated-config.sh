#!/bin/bash

################################################################################
# Deprecated config removed from other scripts in this folder.
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

# Deprecated when chezmoi was added to Sid repo (July 2026)
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
#
# Line wrap ruler
#
#   5   10   15   20   25   30   35   40   45   50   55   60   65   70   75   80
#
################################################################################

