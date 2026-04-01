# phil-gg/dotfiles

## Bootstrap

    ```
    TMPDIR=$(mktemp -d) && /usr/lib/apt/apt-helper download-file \
    "https://raw.githubusercontent.com/phil-gg/dotfiles/refs/heads/main/HOME/dot_config/scripts/01-bootstrap.sh" \
    ${TMPDIR}/ba.sh" && bash "${TMPDIR}/ba.sh"; [ -n "${TMPDIR}" ] && rm -rf "${TMPDIR}"
    ```

## Key Attributes

 - For Debian (and currently primarily for Trixie)
 - Uses [chezmoi](https://www.chezmoi.io/install/#download-a-pre-built-linux-package) for templates with conditionality
 - Uses [1password](https://support.1password.com/install-linux/#arm-or-other-distributions-targz) for secrets management

