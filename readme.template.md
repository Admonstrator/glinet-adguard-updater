<div align="center">

<img src="images/robbenlogo-glinet-small.webp" width="300" alt="GL.iNet Tailscale Logo" style="border-radius: 10px; margin: 20px 0;">

## AdGuard Home Updater for GL.iNet Routers

**Keep AdGuard Home up-to-date on your GL.iNet router with ease!**

[![Latest Release](https://img.shields.io/github/v/release/Admonstrator/glinet-adguard-updater?style=for-the-badge&logo=github&color=blue)](https://github.com/Admonstrator/glinet-adguard-updater/releases/latest) [![Script Version](https://img.shields.io/badge/script-{{SCRIPT_VERSION}}-green?style=for-the-badge&logo=linux)](https://github.com/Admonstrator/glinet-adguard-updater) [![AdGuard Home](https://img.shields.io/badge/AdGuard%20Home-{{ADGUARD_VERSION}}-blue?style=for-the-badge&logo=adguard)](https://github.com/AdguardTeam/AdGuardHome) [![License](https://img.shields.io/github/license/Admonstrator/glinet-adguard-updater?style=for-the-badge)](LICENSE) [![Build Status](https://img.shields.io/github/actions/workflow/status/Admonstrator/glinet-adguard-updater/build-adguardhome.yaml?style=for-the-badge&logo=github-actions&label=Build)](https://github.com/Admonstrator/glinet-adguard-updater/actions/workflows/build-adguardhome.yaml) [![Stars](https://img.shields.io/github/stars/Admonstrator/glinet-adguard-updater?style=for-the-badge)](https://github.com/Admonstrator/glinet-adguard-updater/stargazers)

---

## 💖 Support the Project

If you find this tool helpful, consider supporting its development:

[![GitHub Sponsors](https://img.shields.io/badge/GitHub-Sponsors-EA4AAA?style=for-the-badge&logo=github)](https://github.com/sponsors/admonstrator) [![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/admon) [![Ko-fi](https://img.shields.io/badge/Ko--fi-FF5E5B?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/admon) [![PayPal](https://img.shields.io/badge/PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://paypal.me/aaronviehl)

</div>

---

## ✨ Features

- 🚀 **Automatic Updates** - Fetches and installs the latest AdGuard Home version
- 📦 **Tiny Version Support** - Uses pre-compressed binaries optimized for GL.iNet routers (6 MB vs 32 MB)
- 🎯 **Version Selection** - Install specific AdGuard Home versions
- 💾 **Query Logging Control** - Optionally enable query logging to file
- 🔄 **Persistence Support** - Make installations survive firmware upgrades
- 🛡️ **Safe Backups** - Automatic backup of original files before updates
- ⚡ **Flexible Options** - Multiple flags for customized installations

---

## 📋 Requirements

| Requirement | Details |
|------------|---------|
| **Router** | GL.iNet router with firmware 4.x (including MT-6000 Flint 2 and GL-BE9300 Flint 3) |
| **Free Space** | At least 15 MB (can be bypassed with `--ignore-free-space`) |
| **AdGuard Home** | Pre-installed via GL.iNet firmware (deeply integrated) |

---

## 🚀 Quick Start

Run the updater without cloning the repository:

```bash
wget -O update-adguardhome.sh https://raw.githubusercontent.com/Admonstrator/glinet-adguard-updater/main/update-adguardhome.sh && sh update-adguardhome.sh
```

> ⚠️ **Important:** Do not run this script as a cron job! Manual execution is recommended.

---

## 🎛️ Arguments

The `update-adguardhome.sh` script supports the following arguments:

| Argument | Description |
|----------|-------------|
| `--ignore-free-space` | Bypasses the free space check and disables backup creation. Use with caution on low-storage devices! ⚠️ Not recommended - could break your router if there's insufficient space! |
| `--select-release` | Displays available releases and lets you choose a specific version to install. |

---

## 📚 Usage Examples

### Standard Update

Update to the latest stable release:

```bash
wget -O update-adguardhome.sh https://raw.githubusercontent.com/Admonstrator/glinet-adguard-updater/main/update-adguardhome.sh && sh update-adguardhome.sh
```

### Select a Specific Version

Install a specific AdGuard Home version:

```bash
sh update-adguardhome.sh --select-release
```

The script will display available releases for you to choose from.

### Low Storage Devices

For devices with limited free space (⚠️ use with caution):

```bash
sh update-adguardhome.sh --ignore-free-space
```

> **⚠️ Warning:** This disables safety checks and backup creation. Could potentially break your router if there's not enough free space!

---

## 🔍 Key Features Explained

### 📦 Tiny-AdGuardHome

By default, the script uses pre-compressed AdGuard Home binaries that:
- 🔹 Save significant storage space (6 MB vs 32 MB)
- 🔹 Are optimized specifically for GL.iNet routers
- 🔹 Maintain full functionality
- 🔹 Are recommended for all GL.iNet devices

### 💾 Query Logging

By default, AdGuard Home on GL.iNet routers disables query logging to file to:
- 🔹 Prevent running out of storage space
- 🔹 Prevent flash memory wear
- 🔹 Optimize performance

The script will ask if you want to enable query logging after the update.

#### Manual Query Logging Control

**Enable query logging to file:**

```bash
sed -i '/^querylog:/,/^[^ ]/ s/^  file_enabled: .*/  file_enabled: true/' /etc/AdGuardHome/config.yaml
/etc/init.d/adguardhome restart
```

**Disable query logging to file:**

```bash
sed -i '/^querylog:/,/^[^ ]/ s/^  file_enabled: .*/  file_enabled: false/' /etc/AdGuardHome/config.yaml
/etc/init.d/adguardhome restart
```

### 🔄 Persistence Support

The script offers to make the installation persistent across firmware upgrades by:
- ✅ Adding necessary files to `/etc/sysupgrade.conf`
- ✅ Setting up automatic update checks via `/etc/rc.local`
- ✅ Preserving your AdGuard Home configuration and settings

> ⚠️ **Important:** Factory reset will NOT revert persistent installations!

---

## 🔙 Reverting Changes

Since AdGuard Home is deeply integrated into GL.iNet firmware, reverting changes requires manual steps. Factory reset will **NOT** revert changes if you made the installation persistent!

### Manual Revert Steps

1. Remove the update check script from startup:
   ```bash
   sed -i '/enable-adguardhome-update-check/d' /etc/rc.local
   ```

2. Remove the update check script:
   ```bash
   rm /usr/bin/enable-adguardhome-update-check
   ```

3. Remove persistence entries from `/etc/sysupgrade.conf`:
   - `/root/AdGuardHome_backup.tar.gz`
   - `/etc/AdGuardHome`
   - `/usr/bin/AdGuardHome`
   - `/usr/bin/enable-adguardhome-update-check`
   - `/etc/rc.local`

4. Stop AdGuard Home:
   ```bash
   /etc/init.d/adguardhome stop
   ```

5. ⚠️ **Reset configuration (removes all settings and blocklists!):**
   ```bash
   rm -rf /etc/AdGuardHome
   ```

6. Start AdGuard Home:
   ```bash
   /etc/init.d/adguardhome start
   ```

### Restore from Backup

A backup of the original files is located at `/root/AdGuardHome_backup.tar.gz` (if created).

If issues persist after manual revert, you can restore AdGuard Home to its original state by re-flashing the firmware.

---

## 💬 Feedback

Have questions or feedback? Join the discussion in the [GL.iNet forum](https://forum.gl-inet.com/t/script-update-adguard-home/39398).

---

## ⚠️ Disclaimer

This script is provided **as-is** without any warranty. Use it at your own risk.

**It's in an early stage and not ready for production use.**

**It may potentially:**
- 🔥 Break your router, computer, or network
- 🔥 Cause data loss or configuration issues
- 🔥 Result in an unusable device requiring firmware reflash
- 🔥 Even burn down your house (okay, probably not, but you get the idea)

**You have been warned!**

---

## 🧰 GL.iNet Toolbox

This script is part of the **GL.iNet Toolbox** - a collection of useful scripts for GL.iNet routers:

| Project | Description | Status |
|---------|-------------|--------|
| [AdGuard Home Updater](https://github.com/Admonstrator/glinet-adguard-updater) | Keep AdGuard Home up-to-date | ✅ Active |
| [Tailscale Updater](https://github.com/Admonstrator/glinet-tailscale-updater) | Keep Tailscale up-to-date | ✅ Active |

---

<div align="center">

## 🧰 Part of the GL.iNet Toolbox

This project is part of a comprehensive collection of tools for GL.iNet routers.

**Explore more tools and utilities:**

[![GL.iNet Toolbox](https://img.shields.io/badge/🧰_GL.iNet_Toolbox-Explore_All_Tools-blue?style=for-the-badge)](https://github.com/Admonstrator/glinet-toolbox)

*Discover AdGuard Home Updater, ACME Certificate Manager, and more community-driven projects!*

</div>

---

<div align="center">

**Made with ❤️ by [Admon](https://github.com/Admonstrator) for the GL.iNet Community**

⭐ If you find this useful, please star the repository!

</div>
