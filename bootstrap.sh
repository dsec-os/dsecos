#!/usr/bin/env bash
# DsecOS Official Bootstrap Script
# Repo: https://github.com/dsec-os/dsecos
# Run this once on any fresh machine

set -euo pipefail

REPO_URL="https://github.com/dsec-os/dsecos.git"
TARGET_DIR="${HOME}/dsecos"

echo "Creating DsecOS build environment in ${TARGET_DIR} ..."

# 1. Install system dependencies
if command -v apt-get >/dev/null; then
  sudo apt-get update -qq
  sudo apt-get install -y git wget curl live-build debootstrap qemu-utils \
    binutils zstd gpg dosfstools xorriso mtools unzip make python3-pip \
    ansible calamares calamares-settings-debian zfsutils-linux \
    selinux-basics selinux-policy-dev policycoreutils setools
elif command -v pacman >/dev/null; then
  sudo pacman -Syu --noconfirm git wget curl live-build archiso
else
  echo "Unsupported distro – please use Debian/Ubuntu or open an issue"
  exit 1
fi

# 2. Clone the real monorepo
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

if [ -d ".git" ]; then
  echo "Existing repo found – pulling latest..."
  git pull origin main
else
  git clone "$REPO_URL" .
fi

# 3. Create full SOLID module skeleton if not present
mkdir -p modules/{00-base,10-selinux,20-zfs,30-docker,40-lxd,50-kvm,60-dsecpanel,70-traefik,80-cockpit,90-hardening,99-themes}
mkdir -p {scripts,ansible/roles,selinux-policy,installer,config/{package-lists,includes.chroot/etc,hooks.live}}

# 4. Add minimal files so you can commit immediately
cat > README.md <<'EOF'
# DsecOS – Secure Infrastructure Platform OS
Debian + SELinux Enforcing + ZFS + Docker/LXD/KVM – hardened by default.

Run `./build.sh` to create the ISO.
EOF

cat > build.sh <<'EOF'
#!/usr/bin/env bash
set -e
sudo lb clean
sudo lb build 2>&1 | tee build.log
echo "ISO ready: $(ls -lh live-image-*.iso 2>/dev/null || echo 'not built yet')"
EOF
chmod +x build.sh

cat > .gitignore <<'EOF'
/auto/
/cache/
/chroot/
/config/
/live-image-*.iso
/build.log
/stage/
EOF

# 5. Final message
echo ""
echo "DsecOS repository ready!"
echo ""
echo "   cd ${TARGET_DIR}"
echo "   ./build.sh          # builds the full ISO"
echo ""
echo "   Website: https://dsecos.decadev.co.uk"
echo "   Docs:    https://docs.dsecos.decadev.co.uk"
echo ""
echo "Star the repo if you like it: https://github.com/dsec-os/dsecos"
