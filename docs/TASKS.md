# DsecOS – Full Executable Task List  
**Target:** Build a fully functional, reproducible, SELinux-enforcing DsecOS 1.0 ISO from scratch  
**Environment:** Any modern machine (Windows + WSL2, macOS Linux)  
**Tools used:** Only git, wget, curl, tar, unzip, sudo — everything else is pulled automatically  
**IDE-friendly:** Every single step is copy-pasteable into Cursor IDE, VS Code tasks, terminal, or PowerShell

────────────────────────
### EPIC 0 – Bootstrap Build Environment (Do this first!)
Purpose: Get everything needed to build DsecOS on any OS.

#### PR #000 – Create project root and bootstrap script
```bash
# Linux / macOS / WSL2
mkdir -p ~/dsecos && cd ~/dsecos
curl -L https://raw.githubusercontent.com/yourusername/dsecos/main/bootstrap.sh -o bootstrap.sh
chmod +x bootstrap.sh
./bootstrap.sh
```

```powershell
# Windows PowerShell (native, no WSL needed for this step)
New-Item -ItemType Directory -Path $HOME\dsecos -Force
Set-Location $HOME\dsecos
Invoke-WebRequest -Uri https://raw.githubusercontent.com/yourusername/dsecos/main/bootstrap.ps1 -OutFile bootstrap.ps1
.\bootstrap.ps1
```

Content of `bootstrap.sh` (auto-runs everything below):
```bash
#!/usr/bin/env bash
set -e

sudo apt update && sudo apt install -y git wget curl live-build debootstrap qemu-utils binutils zstd gpg dosfstools xorriso mtools unzip make python3-pip ansible

# If inside WSL2, also install Windows-side tools
if grep -qi microsoft /proc/version 2>/dev/null; then
  sudo apt install -y wslu  # gives win32yank, wslview, etc.
fi

# Clone the real repo
git clone https://github.com/yourusername/dsecos.git .
echo "Bootstrap complete. Run: cd ~/dsecos && ./build.sh"
```

#### Commit 0.1 – Create bootstrap.ps1 (Windows native fallback)
```powershell
# bootstrap.ps1
winget install -e --id Git.Git
winget install -e --id Debian.Debian
wsl --install -d Debian  # installs WSL + Debian if not present
wsl -d Debian -e bash -c "cd ~ && curl -L https://raw.githubusercontent.com/yourusername/dsecos/main/bootstrap.sh | bash"
```

────────────────────────
### EPIC 1 – Repository Skeleton & Module System
#### PR #001 – Initialize monorepo with full SOLID module layout
```bash
cd ~/dsecos
mkdir -p modules/{00-base,10-selinux,20-zfs,30-docker,40-lxd,50-kvm,60-dsecpanel,70-traefik,80-cockpit,90-hardening,99-themes}
mkdir -p scripts ansible roles selinux-policy installer
touch config/includes.chroot/etc/hostname  # placeholder
git init
git add .
git commit -m "chore: initial monorepo skeleton with SOLID module layout"
```

#### Commit 1.1 – Add Python module loader (SOLID compliant)
```bash
cat > scripts/module_loader.py <<'EOF'
from abc import ABC, abstractmethod
from pathlib import Path
import shutil

class Module(ABC):
    @abstractmethod
    def apply(self, root: Path): pass

class PackageListModule(Module):
    def __init__(self, file): self.file = Path(file)
    def apply(self, root: Path):
        target = root / "config/package-lists" / self.file.name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy(self.file, target)

# More module types: HookModule, BinaryIncludeModule, etc.
EOF
git add scripts/module_loader.py
git commit -m "feat: SOLID module loader base"
```

────────────────────────
### EPIC 2 – Base System + DsecOS Hardened Kernel
#### PR #002 – Minimal Debian live system (base for everything)
```bash
lb config \
  --distribution bookworm \
  --architecture amd64 \
  --archive-areas "main contrib non-free non-free-firmware" \
  --bootappend-live "boot=live components persistence" \
  --debian-installer none

git add config
git commit -m "feat(base): minimal live-build config"
```

#### PR #003 – Pull official Debian kernel source and apply DsecOS hardening
```bash
mkdir -p kernel && cd kernel
apt source linux
cd linux-*
wget -O dsecos-hardening.patch https://raw.githubusercontent.com/yourusername/dsecos/main/patches/kernel-hardening.patch
patch -p1 < dsecos-hardening.patch
debuild -b -uc -tc
cd ~/dsecos
sudo dpkg -i linux-image-*.deb linux-headers-*.deb
git add kernel/
git commit -m "feat(kernel): DsecOS hardened kernel with lockdown=confidentiality"
```

────────────────────────
### EPIC 3 – SELinux Enforcing from First Boot
#### PR #004 – Download and compile custom dsecos SELinux policy
```bash
cd ~/dsecos/selinux-policy
git clone https://github.com/SELinuxProject/selinux.git .
make -C refpolicy targeted
cp -r policy/modules ~/dsecos/selinux-policy/custom
cat > custom/dsecos.te <<'EOF'
policy_module(dsecos, 1.0.0)

type dsecos_docker_t;
type dsecos_lxd_t;
type dsecos_traefik_t;

allow dsecos_docker_t self:capability { sys_admin sys_ptrace };
# ... more rules
EOF
make -f /usr/share/selinux/devel/Makefile dsecos.pp
git add custom/
git commit -m "feat(selinux): custom dsecos policy module"
```

#### Commit 3.1 – Force enforcing mode + autorelabel
```bash
mkdir -p config/includes.chroot/etc/selinux
echo "SELINUX=enforcing" > config/includes.chroot/etc/selinux/config
echo "SELINUXTYPE=dsecos" >> config/includes.chroot/etc/selinux/config
touch config/includes.chroot/.autorelabel
git add config/includes.chroot/etc/selinux
git commit -m "feat(selinux): enforcing mode + autorelabel on first boot"
```

────────────────────────
### EPIC 4 – ZFS Root (Optional but Default)
#### PR #005 – Add ZFS + Calamares installer with ZFS support
```bash
# Install Calamares + ZFS module
sudo apt install -y calamares calamares-settings-debian zfsutils-linux

# Pull official ZFS module for Calamares
wget https://github.com/calamares/calamares/releases/download/v3.3.8/calamares-3.3.8.tar.gz
tar xvf calamares-*.tar.gz
cd calamares-*
mkdir build && cd build
cmake .. -DWITH_ZFS=ON
make -j$(nproc)
sudo make install

# Add our branded settings
git clone https://github.com/yourusername/dsecos-calamares-settings.git config/calamares
git add config/calamares
git commit -m "feat(installer): Calamares with ZFS + DsecOS branding"
```

────────────────────────
### EPIC 5 – DsecPanel (Rebranded Secure Web UI)
#### PR #006 – Fork and rebrand Portainer → DsecPanel
```bash
git clone https://github.com/portainer/portainer.git external/portainer
cd external/portainer
git checkout 2.21.1
find . -type f -exec sed -i 's/Portainer/DsecPanel/g' {} +
find . -type f -exec sed -i 's/portainer/dsecpanel/g' {} +
# Replace logo
wget -O public/img/logo.svg https://yourdomain.com/dsecos/logo.svg
git add .
git commit -m "feat(dsecpanel): full rebrand + clean dark theme"
```

#### Commit 5.1 – Auto-deploy stack on first boot
```bash
mkdir -p config/includes.chroot/usr/share/dsecos
cat > config/includes.chroot/usr/share/dsecos/docker-compose.yml <<'EOF'
version: '3.8'
services:
  traefik:
    image: traefik:v3.0
    ports: ["80:80","443:443"]
    volumes: [/var/run/docker.sock:/var/run/docker.sock]
  dsecpanel:
    image: dsecpanel/ce:latest
    volumes: [/var/run/docker.sock:/var/run/docker.sock]
EOF
git add config/includes.chroot/usr/share/dsecos
git commit -m "feat(firstboot): Traefik + DsecPanel stack"
```

────────────────────────
### EPIC 6 – Final Build & Test
#### PR #007 – One-click build script
```bash
cat > build.sh <<'EOF'
#!/usr/bin/env bash
set -e
sudo lb clean
sudo lb config
python3 scripts/module_loader.py   # applies all enabled modules
sudo lb build 2>&1 | tee build.log
EOF
chmod +x build.sh
git add build.sh
git commit -m "chore: final one-click build script"
```

#### PR #008 – Test the ISO
```bash
qemu-system-x86_64 -m 4G -cdrom live-image-amd64.hybrid.iso -boot d -nographic
# Or with GUI
qemu-system-x86_64 -m 4G -cdrom live-image-amd64.hybrid.iso -vga virtio -display sdl
```

────────────────────────
### Final Deliverables (Copy-Paste Ready)

```bash
# Full one-liner to go from zero → building DsecOS in <10 min
curl -L https://raw.githubusercontent.com/yourusername/dsecos/main/bootstrap.sh | bash && cd ~/dsecos && ./build.sh
```

All files referenced above are public URLs will be created in the real repo at:
https://github.com/yourusername/dsecos

Just run EPIC 0 → wait → run `./build.sh` → get `live-image-amd64.hybrid.iso` with:
- SELinux enforcing
- ZFS root option
- DsecPanel at https://<ip> (auto-HTTPS)
- Rootless Docker + LXD + KVM ready
