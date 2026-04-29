# phil-gg/dotfiles

## Bootstrap
```
sudo apt update && sudo apt upgrade -y && sudo apt install -y gpg equivs curl ca-certificates
```
```
curl -fsSL "https://raw.githubusercontent.com/phil-gg/dotfiles/refs/heads/main/HOME/dot_config/scripts/run_after_02-configure-repos-update-pkgs-Debian.sh" | bash
```

## Key Attributes
 - For Debian (and currently primarily for Trixie)
 - Uses [chezmoi](https://www.chezmoi.io/install/#download-a-pre-built-linux-package) for templates with conditional logic
 - Uses [1password](https://support.1password.com/install-linux/#arm-or-other-distributions-targz) for secrets management
