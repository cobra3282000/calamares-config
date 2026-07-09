#!/bin/bash
# Human-readable source for the base64 blob embedded in
# shellprocess-bootfix.conf. This file is NOT executed by Calamares and is
# NOT installed onto the target system - it exists purely so the actual
# fix is reviewable/maintainable without decoding base64 by hand.
#
# WHY BASE64: Calamares expands ${ROOT}/${USER}/etc.-style variables in
# every "command:" string before handing it to the shell (see
# CommandList::run() -> KWordMacroExpander in Calamares' source). This pass
# is not shell-quote-aware, so any bare $word or ${word} anywhere in the
# script text - even inside single quotes - is treated as an unresolved
# Calamares macro and hard-fails the whole job with "Missing variables"
# before the shell ever runs. Base64 has no "$" in its alphabet, so
# encoding this script sidesteps that pass entirely; it's decoded and run
# at actual execution time.
#
# To regenerate the blob after editing this file:
#   base64 -w0 shellprocess-bootfix.source.sh
# then paste the output into shellprocess-bootfix.conf as:
#   command: "-echo <blob> | base64 -d | bash"

{
    # mkinitcpio's autodetect/kms hooks can't see real GPU hardware while
    # running inside the install chroot, so nvidia's early-KMS modules
    # never make it into the initramfs and nouveau is free to race the
    # nvidia driver for the display at boot. Only touch nvidia/nouveau
    # config if the user actually selected an nvidia driver group.
    if pacman -Qq nvidia-open-dkms &>/dev/null || pacman -Qq nvidia-dkms &>/dev/null || pacman -Qq nvidia &>/dev/null; then
        mkdir -p /etc/modprobe.d
        if ! grep -rq '^blacklist nouveau' /etc/modprobe.d/ 2>/dev/null; then
            printf 'blacklist nouveau\noptions nouveau modeset=0\n' > /etc/modprobe.d/blacklist-nouveau.conf
        fi
        if grep -q '^MODULES=(' /etc/mkinitcpio.conf 2>/dev/null && ! grep -q 'nvidia_drm' /etc/mkinitcpio.conf; then
            sed -i 's/^MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_drm nvidia_uvm /' /etc/mkinitcpio.conf
        fi
    fi

    # The live ISO's linux.preset is built for the archiso live-boot
    # environment. If it's still in that form on the installed system,
    # replace it with a normal preset before regenerating images.
    for preset in /etc/mkinitcpio.d/*.preset; do
        [ -f "$preset" ] || continue
        if grep -q "PRESETS=('archiso')" "$preset" 2>/dev/null; then
            kver=$(basename "$preset" .preset)
            {
                echo "ALL_kver=\"/boot/vmlinuz-${kver}\""
                echo "PRESETS=('default')"
                echo "default_image=\"/boot/initramfs-${kver}.img\""
            } > "$preset"
        fi
    done

    mkinitcpio -P
} > /var/log/calamares-bootfix.log 2>&1
exit 0
