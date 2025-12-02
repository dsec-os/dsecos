# Product Requirements Document (PRD) – DsecOS v3  
**Final & Corrected Vision (December 2025)**

**Name:** DsecOS – The Secure Infrastructure Platform OS  
**Tagline:** “Debian + SELinux enforcing + ZFS + Docker/LXD/KVM – hardened by default, beautiful by design”

The “sec” in DsecOS stands exclusively for **Defense-grade Security** – not offensive security / pentest.  
This is a direct competitor to **Rocky Linux + SELinux**, **Fedora Atomic, Proxmox, Harvester, and TrueNAS SCALE — but radically simpler, more modern, and laser-focused on **secure-by-default application platform** use cases (homelab, edge, small/medium business, air-gapped environments).

### Core Philosophy (Non-negotiable)
- Everything runs in **SELinux enforcing mode from first boot  
- Immutable /etc with audit trail (via ansible + git)  
- ZFS root optional, but default on install  
- All containers and VMs are isolated with SELinux + AppArmor + Firejail  
- Zero trust networking (only 443 and 22 open by default)  
- Single beautiful web UI (rebranded, not pentest-themed)

### MVP Scope (v1.0 – “DsecOS Secure Platform Edition” – target April 2026)

| Component              | Technology (final choice)                 | Why |
|-----------------------|-------------------------------------------|-----|
| Base                  | Debian 12/13 minimal + custom kernel      | Stability + huge ecosystem |
| Security Policy       | SELinux enforcing (custom DsecOS policy)  | DoD-grade MAC |
| Kernel                | linux-image-amd64 + DsecOS hardened config| lockdown=confidentiality + custom params |
| Filesystem            | ZFS root (optional ext4 fallback)         | Snapshots, checksums, compression |
| Container Runtime     | Docker (rootless) + Podman                | Industry standard + rootless safe |
| System Containers     | LXD 6.0+ (incus fork)                     | Lightweight VMs |
| Full VMs              | KVM + libvirt + QEMU                      | When you really need a VM |
| Web Control Panel     | DsecPanel (clean fork of Portainer + Cockpit integration) | One single UI |
| Reverse Proxy         | Traefik v3 (auto LetsEncrypt + TCP routing) | Zero-config HTTPS |
| System Management     | Cockpit + 45Drives/cockpit-zfs-manager    | Native ZFS in web UI |
| Updates               | Unattended-upgrades + livepatch (optional)| Zero-downtime kernel updates |

### Final Repository Layout (Extreme Modularity + SOLID)

```
dsec-os/
├── modules/                     # All optional, toggleable
│   ├── 00-base/                 # Debian minimal + DsecOS kernel
│   ├── 10-selinux/              # Custom policy + enforcing mode
│   ├── 20-zfs/                  # ZFS root + datasets
│   ├── 30-docker-rootless/
│   ├── 40-lxd/
│   ├── 50-kvm-libvirt/
│   ├── 60-dsecpanel/            # Our clean, professional fork
│   ├── 70-traefik/
│   ├── 80-cockpit/
│   ├── 90-hardening/            # kernel cmdline, sysctl, limits
│   └── 99-themes/               # Clean corporate dark theme (no skulls)
├── scripts/
│   └── build.py                 # SOLID module loader (Python 3.11)
├── ansible/
│   └── first_boot.yml           # Runs once after install
├── selinux-policy/              # Git submodule – custom DsecOS policy
└── installer/                   # Debian preseed + Calamares modules
```

### Epics → PRs → Subtasks (Only MVP scope)

#### Epic 1 – DsecOS Hardened Kernel & SELinux Enforcing Base

PR #1 – Build custom DsecOS kernel package  
- Based on Debian linux-source  
- Config changes:  
  ```
  CONFIG_LOCKDOWN_CONFIDENTIALITY=y
  CONFIG_SECURITY_SELINUX_BOOTPARAM_VALUE=1
  CONFIG_DEFAULT_SECURITY_SELINUX=y
  CONFIG_MODULE_SIG_ALL=y
  CONFIG_MODULE_SIG_FORCE=y
  ```
- Package name: linux-image-dsecos-amd64

PR #2 – Custom minimal SELinux policy “dsecos”  
- Start from targeted policy  
- Add custom types: dsecos_docker_t, dsecos_lxd_t, dsecos_traefik_t  
- Ship as .pp module + semodule -i  
- First boot → setenforce 1 && touch /.autorelabel

#### Epic 2 – Installer & First-Boot Experience

PR #10 – Calamares installer with two profiles  
- Profile 1: ZFS root + full disk encryption (LUKS on ZFS)  
- Profile 2: Standard ext4 (for old hardware)

PR #11 – First-boot Ansible playbook (idempotent)  
Tasks:
- Install Docker rootless for user “admin”
- Deploy Traefik + DsecPanel stack
- Create ZFS datasets: rpool/{docker,lxd,vms,data}
- Enable cockpit.socket + traefik service
- Generate random 32-char admin password → show on console + QR code

#### Epic 3 – DsecPanel (Clean Rebranded Web UI)

PR #20 – Fork Portainer → DsecPanel  
- New name, logo (simple geometric “D”), color scheme (#0d1117 background + #00ff9d accents)  
- Remove all donation/enterprise nags  
- Add custom dashboard cards:  
   - SELinux status  
   - ZFS pool health  
   - Active AppArmor profiles  
   - System audit log summary

Accessible at https://<ip>/ (Traefik terminates TLS)

#### Epic 4 – Hardening Module (Non-Negotiable)

PR #30 – 90-hardening module applies:
```bash
# /etc/sysctl.d/99-dsecos.conf
kernel.kptr_restrict=2
kernel.dmesg_restrict=1
net.ipv4.conf.all.rp_filter=1
fs.protected_fifos=2
fs.protected_regular=2
```

- ufw → allow only 22/tcp, 80/tcp, 443/tcp  
- AppArmor profiles in enforcing for docker, traefik, cockpit  
- auditd rules for all execve, chmod, etc.

#### Epic 5 – CI/CD & Signed Reproducible Builds

PR #40 – GitHub Actions nightly pipeline  
- Builds ISO inside debian:bookworm container  
- Runs semodule -B && setenforce 1 in chroot tests  
- Signs ISO + kernel .deb with DsecOS Release Key  
- Publishes to https://dl.dsecos.org

### Deliverable – DsecOS 1.0 ISO (April 2026)

- Size: ~1.3 GB hybrid ISO  
- Install time: < 8 minutes  
- After reboot → open https://ip → login with one-time password from console  
- SELinux = Enforcing (shown in banner)  
- ZFS health, Docker, LXD, KVM all available  
- Zero manual configuration needed
