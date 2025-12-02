Here are the **official DsecOS architecture diagrams** in clean, copy-pasteable **Mermaid.js** syntax — perfect for README.md, docs site, or presentations.

### 1. High-Level System Architecture (Hero Diagram)
```mermaid
graph TD
    A["DsecOS Live/Installed System<br/>Debian 12/13 • Bookworm • amd64"] --> B["Hardened Linux Kernel<br/>lockdown=confidentiality • module signing"]
    A --> C["SELinux Enforcing<br/>Custom dsecos policy • targeted + strict"]
    A --> D["ZFS Root (optional)<br/>rpool/ROOT • rpool/docker • rpool/lxd • rpool/vms"]
    A --> E["DsecPanel Web UI<br/>https://dsecos.local • Traefik v3 reverse proxy"]
    
    E --> F["Docker Engine<br/>rootless • dockremap • AppArmor"]
    E --> G["LXD / Incus<br/>system containers • snapshots"]
    E --> H["libvirt + QEMU/KVM<br/>full virtualization"]
    E --> I["Cockpit<br/>ZFS manager • system updates • audit logs"]

    style A fill:#0d1117,stroke:#00ff9d,color:#fff
    style E fill:#1a1f2e,stroke:#00ff9d,color:#fff
```

### 2. Module System Architecture (SOLID in Action)
```mermaid
graph LR
    Build[./build.sh] --> Loader[scripts/module_loader.py<br/>SOLID Module Registry]
    
    Loader --> M00[modules/00-base]
    Loader --> M10[modules/10-selinux]
    Loader --> M20[modules/20-zfs]
    Loader --> M30[modules/30-docker]
    Loader --> M40[modules/40-lxd]
    Loader --> M50[modules/50-kvm]
    Loader --> M60[modules/60-dsecpanel]
    Loader --> M90[modules/90-hardening]
    Loader --> M99[modules/99-themes]

    M00 -->|package-lists/*.chroot| LB[live-build config/]
    M10 -->|includes.chroot/etc/selinux| LB
    M60 -->|hooks.live/*.hook.chroot| LB
    M99 -->|includes.binary/*| LB

    LB --> ISO[DsecOS ISO<br/>live-image-amd64.hybrid.iso]
    
    style Loader fill:#00ff9d,color:#000
    style ISO fill:#0d1117,stroke:#00ff9d,stroke-width:4px
```

### 3. First-Boot & Runtime Flow
```mermaid
sequenceDiagram
    participant User
    participant BIOS
    participant GRUB
    participant Kernel
    participant Init
    participant FirstBoot
    participant DsecPanel

    User->>BIOS: Boot from USB/ISO
    BIOS->>GRUB: DsecOS Dark Theme
    GRUB->>Kernel: boot=live persistence
    Kernel->>Init: systemd + live-boot
    Init->>FirstBoot: /etc/rc.local or hook
    FirstBoot->>FirstBoot: Install Docker (if missing)
    FirstBoot->>FirstBoot: docker compose up -d (Traefik + DsecPanel)
    FirstBoot->>FirstBoot: touch /.autorelabel && reboot
    Note over FirstBoot,DsecPanel: SELinux relabeling (1–3 min)
    Kernel->>DsecPanel: https://dsecos.local ready
    User->>DsecPanel: Manage containers, LXD, VMs, ZFS
```

### 4. Security Layers Stack
```mermaid
graph TD
    subgraph "Physical / VM"
        HW[Hardware / x86_64]
    end

    subgraph "Kernel"
        K[Linux 6.1+<br/>DsecOS hardened config]
    end

    subgraph "MAC"
        SEL[SELinux Enforcing<br/>dsecos_t domains]
        AA[AppArmor profiles]
    end

    subgraph "Runtime"
        D[Docker rootless]
        L[LXD privileged containers]
        V[QEMU/KVM + sVirt]
    end

    subgraph "Network"
        T[Traefik • Auto-LetsEncrypt • mTLS]
    end

    subgraph "Management"
        P[DsecPanel Web UI<br/>Cockpit Integration]
    end

    HW --> K --> SEL --> AA --> D & L & V --> T --> P

    style SEL fill:#c9f2ff,stroke:#00ff9d
    style K fill:#1a1f2e,stroke:#00ff9d,color:#fff
    style P fill:#0d1117,stroke:#00ff9d,color:#fff
```

### 5. Repository Structure (Tree View)
```bash
"dsecos/ (monorepo)"
  "modules/"
    "00-base/"
    "10-selinux/"
    "20-zfs/"
    "30-docker/"
    "40-lxd/"
    "50-kvm/"
    "60-dsecpanel/"
    "70-traefik/"
    "80-cockpit/"
    "90-hardening/"
    "99-themes/"
  "config/"
    "package-lists/"
    "includes.chroot/"
    "includes.binary/"
    "hooks.live/"
  "scripts/"
    "module_loader.py"
    "build.sh"
  "ansible/"
  "installer/"
  "assets/branding/"
    "dsecos-wallpaper.jpg"
    "logo.svg"
    "grub-background.png"
```

```mermaid
graph TD
    A[DsecOS] --> B[Hardened Kernel] --> C[SELinux Enforcing] --> D[DsecPanel]
```
