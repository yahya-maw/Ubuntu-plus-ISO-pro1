#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

echo "=== 1. Preparing Virtual Environment ==="
# ربط المسارات الحيوية لضمان عمل apt-get داخل الـ ISO
sudo mount --bind /dev edit/dev
sudo mount --bind /run edit/run
sudo mount -t proc /proc edit/proc
sudo mount -t sysfs /sys edit/sys
sudo cp /etc/resolv.conf edit/etc/

echo "=== 2. System DNA Modification (Chroot) ==="
# الدخول لقلب النظام وتثبيت كل شيء حرفياً
sudo chroot edit /bin/bash << 'EOF'
export DEBIAN_FRONTEND=noninteractive

# تحديث وضبط المستودعات
apt-get update
apt-get install -y software-properties-common curl wget gnupg

# إضافة مستودعات Waydroid و MX Linux و Wine
curl -s https://repo.waydro.id | bash
add-apt-repository ppa:mx-linux/mx-tools -y
dpkg --add-architecture i386
mkdir -pm755 /etc/apt/keyrings
wget -O - https://dl.winehq.org/wine-builds/winehq.key | gpg --dearmor | tee /etc/apt/keyrings/winehq-archive.key > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/winehq-archive.key] https://dl.winehq.org/wine-builds/ubuntu/ noble main" | tee /etc/apt/sources.list.d/winehq.list

apt-get update

# تثبيت الحزمة الكاملة للـ HP G62
apt-get install -y xubuntu-desktop yaru-theme-gtk yaru-theme-icon \
  waydroid winehq-staging mx-apps mx-tools synaptic zram-config \
  plymouth-theme-ubuntu-logo htop

# تنظيف الزيادات لتوفير مساحة الـ ISO
apt-get purge -y snapd unattended-upgrades
apt-get autoremove -y
apt-get clean
exit
EOF

echo "=== 3. Fine-Tuning Performance & GUI ==="
# إعدادات الـ ZRAM والسرعة
echo "ALGO=lz4" | sudo tee -a edit/etc/default/zramswap
echo "vm.swappiness=150" | sudo tee -a edit/etc/sysctl.conf

# إعدادات الـ Double Click لفتح APK و EXE مباشرة
sudo mkdir -p edit/usr/share/applications/
cat << 'EOF' | sudo tee edit/usr/share/applications/custom-handler.desktop
[Desktop Entry]
Type=Application
Name=Install APK/EXE
Exec=bash -c "if [[ %f == *.apk ]]; then waydroid app install %f; else wine %f; fi"
Icon=system-run
MimeType=application/vnd.android.package-archive;application/x-ms-dos-executable;
EOF

echo "application/vnd.android.package-archive=custom-handler.desktop" | sudo tee -a edit/usr/share/applications/defaults.list
echo "application/x-ms-dos-executable=custom-handler.desktop" | sudo tee -a edit/usr/share/applications/defaults.list

echo "=== 4. Unmounting ==="
sudo umount -l edit/dev || true
sudo umount -l edit/run || true
sudo umount -l edit/proc || true
sudo umount -l edit/sys || true

echo "✅ All internal modifications finished!"
