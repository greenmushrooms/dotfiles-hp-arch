# Notes

## Inspiron 3501 HDMI cap (2026-05-15)

dDell Inspiron 3501 (TigerLake i7-1165G7, Iris Xe, PCI 8086:9a49) HDMI port is **HDMI 1.4, hard-capped at 1920x1080@60** per Dell official spec. Motherboard-level limit, not GPU/cable.

External LG UltraGear (3440x1440 native, serial 010NTEPA5588) over HDMI from this laptop will only ever do 1080p. Cable + monitor work fine on other machines with HDMI 2.0+ ports.

**Why noted:** spent a session attempting EDID firmware override (`/lib/firmware/edid/lg_ultragear.bin` + `drm.edid_firmware=HDMI-A-1:edid/lg_ultragear.bin` in systemd-boot entry + `FILES=()` in mkinitcpio.conf + `MODULES=(i915)`). Override silently never loaded — sysfs `edid` stayed 0 bytes, modes stayed 1080p. Two layers stack: (1) i915 EDID firmware override mechanism brittle across kernel versions, (2) even if loaded, driver filters out-of-spec modes that exceed connector hardware limits. Some Win11 users report 4K via YCBCR_420 chroma subsampling trick — Linux i915 path didn't reproduce it.

**Don't retry.** Only paths to higher res: replace HDMI with USB-C/DP (laptop has neither — only ethernet + HDMI), or use a different host machine.

### Rollback

Per `~/post-reboot.md` recovery section (run if EDID override files still present):

```
sudo cp /boot/loader/entries/2026-03-14_15-56-54_linux.conf.bak /boot/loader/entries/2026-03-14_15-56-54_linux.conf
sudo sed -i 's|^FILES=(/lib/firmware/edid/lg_ultragear.bin)|FILES=()|' /etc/mkinitcpio.conf
sudo mkinitcpio -P
```

Then ensure `hypr/.config/hypr/hyprland.lua` has `mode = "1920x1080@60"` for HDMI-A-1.

### Kernel context

Kernel update 2026-05-15 14:35: `linux 6.19.14 → 7.0.7-arch2-1`. Reboot triggered the EDID override attempt. Override never worked under either kernel — assumed regression but actually hardware cap.
