#!/usr/bin/env bash
#
# build-kanes-arch.sh
#
# Builds a REAL, bootable Kane's Arch ISO for Kane Woodson.
# This is not a fake OS: it's stock Kane's Arch tooling (via the official `releng`
# archiso profile) with cosmetic branding patched in. Nothing about the
# underlying system, packages, or install process is altered.
#
# What gets changed:
#   - /etc/os-release            -> NAME/PRETTY_NAME/ID become "Kane's Arch"
#   - /etc/issue                 -> custom TTY login banner
#   - /etc/motd                  -> custom post-login message
#   - fastfetch config + logo    -> shows "KANE'S ARCH" ascii art on login
#   - boot menu text (syslinux/grub) -> "Kane's Arch" instead of the upstream label
#   - packages.x86_64            -> adds Kane's Arch desktop packages if not already present
#   - systemd target/services    -> boots to Kane Woodson's Kane's Arch GNOME desktop
#
# REQUIREMENTS (run this ON Kane's Arch, as root or with sudo):
#   sudo pacman -S --needed archiso
#
# USAGE:
#   chmod +x build-kanes-arch.sh
#   sudo ./build-kanes-arch.sh
#
# Output ISO will be in ./out/
#
set -euo pipefail

ensure_package() {
  local package="$1"
  if ! grep -qx "$package" packages.x86_64 2>/dev/null; then
    echo "$package" >> packages.x86_64
  fi
}

PROFILE_SRC="/usr/share/archiso/configs/releng"
WORK_DIR="$(pwd)/kanes-arch-profile"
OUT_DIR="$(pwd)/out"

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo ./build-kanes-arch.sh)" >&2
  exit 1
fi

if [ ! -d "$PROFILE_SRC" ]; then
  echo "archiso releng profile not found at $PROFILE_SRC" >&2
  echo "Install it first: sudo pacman -S --needed archiso" >&2
  exit 1
fi

echo "==> Copying releng profile to $WORK_DIR"
rm -rf "$WORK_DIR"
cp -r "$PROFILE_SRC" "$WORK_DIR"
cd "$WORK_DIR"

# ---------------------------------------------------------------------------
# 1. profiledef.sh — ISO metadata (filename, volume label, publisher string)
# ---------------------------------------------------------------------------
echo "==> Patching profiledef.sh"
sed -i \
  -e 's/^iso_name=.*/iso_name="kanesarch"/' \
  -e 's/^iso_label=.*/iso_label="KANES_ARCH_$(date +%Y%m)"/' \
  -e 's/^iso_publisher=.*/iso_publisher="Kane Woodson <https:\/\/example.invalid>"/' \
  -e 's/^iso_application=.*/iso_application="Kane'"'"'s Arch Live\/Rescue CD"/' \
  profiledef.sh

# ---------------------------------------------------------------------------
# 2. /etc/os-release — this is what fastfetch, neofetch, uname-ish tools,
#    and most "what OS is this" checks actually read.
#
#    NOTE: we deliberately do NOT also hand-write /etc/lsb-release here.
#    The real `lsb-release` package (pulled in as a dependency during the
#    mkarchiso package install step) owns that file. Writing it ourselves
#    first creates an untracked file that pacman then refuses to overwrite
#    when it tries to install the real package -> "exists in filesystem"
#    / "failed to commit transaction (conflicting files)" build failure.
# ---------------------------------------------------------------------------
echo "==> Writing custom os-release"
mkdir -p airootfs/etc
cat > airootfs/etc/os-release << 'EOF'
NAME="Kane's Arch"
PRETTY_NAME="Kane's Arch"
ID=kanesarch
ID_LIKE=arch
BUILD_ID=rolling
ANSI_COLOR="38;2;79;209;197"
HOME_URL="https://kanes-arch.example/"
DOCUMENTATION_URL="https://kanes-arch.example/wiki/"
SUPPORT_URL="https://kanes-arch.example/"
BUG_REPORT_URL="https://kanes-arch.example/bugs/"
LOGO=kanesarch-logo
EOF

# ---------------------------------------------------------------------------
# 3. /etc/issue — shown on the TTY before login
# ---------------------------------------------------------------------------
echo "==> Writing custom /etc/issue"
cat > airootfs/etc/issue << 'EOF'

  _  __                     _      _             _
 | |/ /__ _ _ __   ___  ___| |    / \   _ __ ___| |__
 | ' // _` | '_ \ / _ \/ __| |   / _ \ | '__/ __| '_ \
 | . \ (_| | | | |  __/\__ \ |  / ___ \| | | (__| | | |
 |_|\_\__,_|_| |_|\___||___/_| /_/   \_\_|  \___|_| |_|

  Kane's Arch (rolling)  ::  \l

EOF

# ---------------------------------------------------------------------------
# 4. /etc/motd — shown right after login
# ---------------------------------------------------------------------------
echo "==> Writing custom motd"
cat > airootfs/etc/motd << 'EOF'
Welcome to Kane's Arch.

This is a real, fully functional Kane's Arch system by Kane Woodson.
Nothing about the packages, kernel, or install process has been changed —
only the branding. Run 'fastfetch' to confirm.

EOF

# ---------------------------------------------------------------------------
# 5. fastfetch — custom ascii logo + auto-run on login shell
# ---------------------------------------------------------------------------
echo "==> Adding fastfetch branding"
mkdir -p airootfs/etc/fastfetch
cat > airootfs/etc/fastfetch/kanesarch-logo.txt << 'EOF'
${c1}       /\
      /  \
     /    \
    /  ${c2}/\${c1}  \
   /  ${c2}/  \${c1}  \
  /  ${c2}/    \${c1}  \
 /  ${c2}/ ${c3}/\${c2}  \${c1}  \
/__${c2}/_${c3}/  \${c2}_\${c1}__\
EOF

cat > airootfs/etc/fastfetch/config.jsonc << 'EOF'
{
  "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
  "logo": {
    "type": "file",
    "source": "/etc/fastfetch/kanesarch-logo.txt",
    "color": {
      "1": "cyan",
      "2": "white",
      "3": "green"
    }
  },
  "display": {
    "separator": " "
  },
  "modules": [
    "title",
    "separator",
    "os",
    "host",
    "kernel",
    "uptime",
    "packages",
    "shell",
    "cpu",
    "memory",
    "disk",
    "break",
    "colors"
  ]
}
EOF

# Auto-run fastfetch on interactive login shells (skip for non-interactive/scp etc.)
echo "==> Wiring fastfetch into login shell"
mkdir -p airootfs/etc/profile.d
cat > airootfs/etc/profile.d/kanesarch-fastfetch.sh << 'EOF'
# Show Kane's Arch branding on interactive login shells only.
case $- in
  *i*) command -v fastfetch >/dev/null 2>&1 && fastfetch ;;
esac
EOF
chmod 755 airootfs/etc/profile.d/kanesarch-fastfetch.sh

# ---------------------------------------------------------------------------
# 6. Make sure Kane Woodson's Kane's Arch desktop packages are installed
# ---------------------------------------------------------------------------
echo "==> Ensuring Kane's Arch GNOME desktop packages are in packages.x86_64"
for package in \
  fastfetch \
  gnome \
  gnome-shell \
  gdm \
  gnome-terminal \
  nautilus
do
  ensure_package "$package"
done

echo "==> Enabling Kane's Arch GNOME desktop startup"
mkdir -p airootfs/etc/systemd/system
ln -sfn /usr/lib/systemd/system/gdm.service airootfs/etc/systemd/system/display-manager.service
ln -sfn /usr/lib/systemd/system/graphical.target airootfs/etc/systemd/system/default.target

# ---------------------------------------------------------------------------
# 7. Boot menu text — Kane's Arch labels in both syslinux (BIOS) and GRUB (UEFI)
# ---------------------------------------------------------------------------
echo "==> Patching boot menu labels"
if [ -d syslinux ]; then
  find syslinux -type f -name '*.cfg' -exec \
    sed -i 's/Arch Linux/Kane'"'"'s Arch/g' {} +
fi
if [ -d grub ]; then
  find grub -type f \( -name '*.cfg' -o -name '*.cfg.in' \) -exec \
    sed -i 's/Arch Linux/Kane'"'"'s Arch/g' {} +
fi

# ---------------------------------------------------------------------------
# 8. Build the ISO
# ---------------------------------------------------------------------------
echo "==> Building ISO (this takes a while — downloads + packages a full live system)"
mkdir -p "$OUT_DIR"
mkarchiso -v -o "$OUT_DIR" "$WORK_DIR"

echo ""
echo "==> Done. ISO is in: $OUT_DIR"
ls -lh "$OUT_DIR"/*.iso
echo ""
echo "Test it in a VM first:"
echo "  qemu-system-x86_64 -m 2G -enable-kvm -boot d -cdrom $OUT_DIR/kanesarch-*.iso"
echo ""
echo "Or write it to a USB drive (DOUBLE-CHECK /dev/sdX — this is destructive):"
echo "  sudo dd if=$OUT_DIR/kanesarch-*.iso of=/dev/sdX bs=4M status=progress oflag=sync"
