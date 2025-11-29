<div align="center">

<img src="images/robbenlogo-glinet-small.webp" width="300" alt="GL.iNet AdGuard Home Logo" style="border-radius: 10px; margin: 20px 0;">

## AdGuard Home Updater for GL.iNet Routers

**Keep AdGuard Home up-to-date on your GL.iNet router with ease!**

[![Latest Release](https://img.shields.io/github/v/release/Admonstrator/glinet-adguard-updater?style=for-the-badge&logo=github&color=blue)](https://github.com/Admonstrator/glinet-adguard-updater/releases/latest) [![License](https://img.shields.io/github/license/Admonstrator/glinet-adguard-updater?style=for-the-badge)](LICENSE) [![Stars](https://img.shields.io/github/stars/Admonstrator/glinet-adguard-updater?style=for-the-badge)](https://github.com/Admonstrator/glinet-adguard-updater/stargazers)

---

## 💖 Support the Project

If you find this tool helpful, consider supporting its development:

[![GitHub Sponsors](https://img.shields.io/badge/GitHub-Sponsors-EA4AAA?style=for-the-badge&logo=github)](https://github.com/sponsors/admonstrator) [![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/admon) [![Ko-fi](https://img.shields.io/badge/Ko--fi-FF5E5B?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/admon) [![PayPal](https://img.shields.io/badge/PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://paypal.me/aaronviehl)

</div>

---

## 📖 About

This script automatically fetches and installs the latest AdGuard Home version, optimized specifically for GL.iNet routers. Keep your AdGuard Home installation current with just one command!

Created by [Admon](https://forum.gl-inet.com/u/admon/) for the GL.iNet community. Tested on nearly all GL.iNet routers with firmware 4.x.

> 🎖️ **Community Maintained** – Part of the [GL.iNet Toolbox](https://github.com/Admonstrator/glinet-toolbox) project
> ⚠️ **Independent Project** – Not officially affiliated with GL.iNet or AdGuard

---

## ✨ Features

- 🚀 **Automatic Updates** – Fetches and installs the latest AdGuard Home version
- 📦 **Tiny Version Support** – Uses pre-compressed binaries optimized for GL.iNet routers (6 MB vs 32 MB)
- 🎯 **Version Selection** – Install specific AdGuard Home versions
- 💾 **Query Logging Control** – Optionally enable query logging to file
- 🔄 **Persistence Support** – Make installations survive firmware upgrades
- 🛡️ **Safe Backups** – Automatic backup of original files before updates
- ⚡ **Flexible Options** – Multiple flags for customized installations

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
wget -q https://get.admon.me/adguard -O update-adguardhome.sh ; sh update-adguardhome.sh
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
wget -q https://get.admon.me/adguard -O update-adguardhome.sh ; sh update-adguardhome.sh
```

### Select a Specific Version

Install a specific AdGuard Home version:

```bash
wget -q https://get.admon.me/adguard -O update-adguardhome.sh ; sh update-adguardhome.sh --select-release
```

The script will display available releases for you to choose from.

### Low Storage Devices

For devices with limited free space (⚠️ use with caution):

```bash
wget -q https://get.admon.me/adguard -O update-adguardhome.sh ; sh update-adguardhome.sh --ignore-free-space
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

## 💡 Getting Help

Need assistance or have questions?

- 💬 [Join the discussion on GL.iNet Forum](https://forum.gl-inet.com/t/script-update-adguard-home/39398) – Community support
- 💬 [Join GL.iNet Discord](https://link.gl-inet.com/website-discord-support) – Real-time chat
- 🐛 [Report issues on GitHub](https://github.com/Admonstrator/glinet-adguard-updater/issues) – Bug reports and feature requests
- 📧 Contact via forum private message – For private inquiries

---

## ⚠️ Disclaimer

This script is provided **as-is** without any warranty. Use it at your own risk.

It may potentially:
- 🔥 Break your router, computer, or network
- 🔥 Cause unexpected system behavior
- 🔥 Even burn down your house (okay, probably not, but you get the idea)

**You have been warned!**

Always read the documentation carefully and understand what a script does before running it.

---

## 👥 Contributors

Special thanks to:

- All the testers and feedback providers in the GL.iNet forum!
- Copilot – Yeah, I am using AI to help write code. But I review and test everything thoroughly!

Want to contribute? Pull requests are welcome!

---

## 📜 License

This project is licensed under the **MIT License** – see the [LICENSE](LICENSE) file for details.

---

<div align="center">

## 🧰 Part of the GL.iNet Toolbox

This project is part of a comprehensive collection of tools for GL.iNet routers.

**Explore more tools and utilities:**

[![GL.iNet Toolbox](https://img.shields.io/badge/🧰_GL.iNet_Toolbox-Explore_All_Tools-blue?style=for-the-badge)](https://github.com/Admonstrator/glinet-toolbox)

*Discover Tailscale Updater, ACME Certificate Manager, and more community-driven projects!*

</div>

---

<div align="center">

**Made with ❤️ by [Admon](https://github.com/Admonstrator) for the GL.iNet Community**

⭐ If you find this useful, please star the repository!

</div>
