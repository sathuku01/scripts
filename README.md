# Brave Browser Installer (No Sudo Required)

Automatically installs Brave Browser on managed Linux PCs where you don't have sudo access. The script downloads the official `.deb` package from GitHub and extracts it directly to your user directory.

## Features

- ✅ No sudo required - installs entirely in `~/.local/`
- ✅ Downloads latest Brave version automatically
- ✅ Cleans up old installations before installing
- ✅ Creates desktop entry (app menu integration)
- ✅ Adds `brave` command to your PATH
- ✅ Backs up existing config before removal (optional)
- ✅ Works on x86_64 and ARM64 architectures

## Requirements

- Linux operating system
- `curl` or `wget` for downloading
- `ar` (usually part of `binutils` - typically pre-installed)
- `tar` for extraction

## Installation

### 1. Download the script

```
curl -O https://raw.githubusercontent.com/sathuku01/scripts/main/brave-installer.sh
# or
wget https://raw.githubusercontent.com/sathuku01/scripts/main/brave-installer.sh
```
#### 2. Make it executable
```
chmod +x brave-installer.sh
```
### 3. Run the script
```
./brave-installer.sh
```
### Usage
## Basic installation
Simply run the script and follow the prompts:

```
./brave-installer.sh
```
You'll be asked:

Whether to remove old Brave files before installing

Whether to launch Brave after installation completes

### After installation
## Restart your terminal or run:

```
source ~/.bashrc
```
## Launch Brave by typing:

```
brave
```
Or use the desktop shortcut - Brave will appear in your application menu

### Complete uninstall
To completely remove Brave and all its files:

```
./brave-installer.sh
# When prompted, choose 'y' to remove old files
# Then Ctrl+C to cancel the installation after cleanup
```
Or manually remove:

```
rm -rf ~/.local/share/brave
rm -f ~/.local/bin/brave
rm -f ~/.local/share/applications/brave-browser.desktop
rm -rf ~/.config/BraveSoftware  # Caution: removes bookmarks/passwords
rm -rf ~/.cache/BraveSoftware
```
### What the script does
Creates directories in `~/.local/` (standard user-local location)

Fetches the latest Brave version from GitHub API

Downloads the official .deb package from GitHub releases

Extracts the .deb using ar and tar (no sudo needed)

Copies Brave binary and resources to ~/.local/share/brave/

Creates a launcher script in ~/.local/bin/brave

Adds ~/.local/bin to your PATH in .bashrc

Installs desktop icon and creates .desktop entry

Verifies the installation by checking the binary

### Directory structure
```
~/.local/
├── bin/
│   └── brave                    # Launcher script
├── share/
│   ├── brave/                   # Brave binary and resources
│   ├── applications/
│   │   └── brave-browser.desktop # Desktop entry
│   └── icons/
│       └── brave-browser.png    # Application icon
```
### Configuration
Edit the script to customize:

```
# At the top of the script
BRAVE_VERSION="latest"           # Change to specific version like "1.90.128"
CLEAN_OLD_INSTALL="yes"          # Auto-clean without asking
CLEAN_CONFIG="no"                # Set to "yes" to remove bookmarks/passwords
CLEAN_CACHE="yes"                # Remove cache during cleanup
BACKUP_CONFIG="yes"              # Backup before removal
```
### Troubleshooting
## "ar: command not found"
Install binutils (may require sudo for this one-time install):

```
# Debian/Ubuntu
sudo apt install binutils

# RHEL/CentOS/Fedora
sudo yum install binutils
```
Download fails
The script tries multiple URL patterns. If all fail:

Visit: https://github.com/brave/brave-browser/releases

Find your version and download the .deb manually

Place it in `/tmp/` and the script will detect it

Brave doesn't launch
Check if the binary exists:

```
ls -la ~/.local/share/brave/brave
If missing, re-run the installation script.
```

License
MIT

Contributing
Issues and pull requests welcome!

```

Just copy everything from the ` ```markdown ` line to the final ` ``` ` and save it as `README.md`.
