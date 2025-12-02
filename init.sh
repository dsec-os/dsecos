cd ~/dsecos

# 1. Minimal useful base system
mkdir -p modules/00-base
cat > modules/00-base/packages.list.chroot <<EOF
linux-image-amd64
zsh
curl
sudo
network-manager
xfce4
lightdm
firefox-esr
EOF

# 2. Force SELinux enforcing + autorelabel
mkdir -p config/includes.chroot/etc/selinux
echo -e "SELINUX=enforcing\nSELINUXTYPE=targeted" > config/includes.chroot/etc/selinux/config
touch config/includes.chroot/.autorelabel

# 3. Simple dark branding (GRUB + LightDM)
mkdir -p config/includes.binary/isolinux
wget -O config/includes.binary/isolinux/splash.png https://raw.githubusercontent.com/dsec-os/assets/main/branding/splash.png
mkdir -p config/includes.chroot/usr/share/backgrounds
wget -O config/includes.chroot/usr/share/backgrounds/dsecos.jpg https://raw.githubusercontent.com/dsec-os/assets/main/branding/wallpaper.jpg

# 4. Hostname + live user
echo "dsecos" > config/includes.chroot/etc/hostname
echo "live" > config/includes.chroot/etc/live/config/username

#5. One-line build script with auto-clean
cat > build.sh <<'EOF'
#!/usr/bin/env bash
set -e
sudo lb clean
sudo lb config
sudo lb build 2>&1 | tee build.log
EOF
chmod +x build.sh

#6. Commit everything
git add .
git commit -m "feat: first bootable + branded + SELinux-enforcing minimal DsecOS"
