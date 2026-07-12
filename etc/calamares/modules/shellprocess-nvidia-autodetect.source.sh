#!/bin/bash
# Human-readable source for the base64 blob embedded in
# shellprocess-nvidia-autodetect.conf. This file is NOT executed by
# Calamares and is NOT installed onto the target system - it exists purely
# so the actual fix is reviewable/maintainable without decoding base64 by
# hand.
#
# WHY BASE64: see shellprocess-bootfix.source.sh in this directory for the
# full explanation of Calamares' variable-expansion pass (KWordMacroExpander
# in CommandList::run()). Same issue applies here since this script uses
# bare $ shell variables.
#
# To regenerate the blob after editing this file:
#   base64 -w0 shellprocess-nvidia-autodetect.source.sh
# then paste the output into shellprocess-nvidia-autodetect.conf as:
#   command: "-echo <blob> | base64 -d | bash"
#
# WHY THIS EXISTS: relying on the user to notice and tick the "Nvidia"
# checkbox on the drivers page is exactly what causes broken installs.
# Skip it on an nvidia card - especially Turing/Ampere/Ada, which need GSP
# firmware that nouveau alone can't supply - and the system boots to a
# resolution-locked single-screen framebuffer fallback, or no signal at
# all once someone tries to bolt the driver on after the fact. Detect the
# GPU directly from PCI (sysfs) instead of trusting a checkbox, and
# install the standard driver set whenever nvidia hardware is present,
# regardless of what was (or wasn't) selected on the drivers page.
{
    NVIDIA_FOUND=0
    for dev in /sys/bus/pci/devices/*/; do
        vendor=$(cat "${dev}vendor" 2>/dev/null)
        class=$(cat "${dev}class" 2>/dev/null)
        # 0x10de = NVIDIA. Class 0300 = VGA controller, 0302 = 3D controller
        # (covers secondary/muxless GPUs on hybrid laptops too).
        if [ "$vendor" = "0x10de" ] && { [ "${class:2:4}" = "0300" ] || [ "${class:2:4}" = "0302" ]; }; then
            NVIDIA_FOUND=1
            break
        fi
    done

    # If the user already picked one of the nvidia groups on the drivers
    # page, pacman will just no-op on the --needed install below - but skip
    # the sync/install entirely in that case to save time.
    if [ "$NVIDIA_FOUND" = "1" ] && ! pacman -Qq nvidia-open-dkms &>/dev/null && ! pacman -Qq nvidia-dkms &>/dev/null && ! pacman -Qq nvidia &>/dev/null; then
        pacman -Sy --needed --noconfirm nvidia-open-dkms nvidia-utils nvidia-settings lib32-nvidia-utils
    fi
} > /var/log/calamares-nvidia-autodetect.log 2>&1
exit 0
