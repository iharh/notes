# reparing

## dd

```
sudo dd bs=4M of=/dev/sda status=progress oflag=sync status=progress if=<dist>.iso
```

## rhino dist grub nomodeset

```
e -> splash -> nomodeset -> F10
```

## chroot

```
sudo lsblk
sudo mount /dev/nvme0n1p… /mnt
sudo mount /dev/nvme0n1p… /mnt/boot/efi/
for i in /dev /dev/pts /proc /sys /run; do sudo mount -B $i /mnt$i; done
sudo chroot /mnt
```
## uefi

https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface/Secure_Boot

## UMS/KMS

* https://wiki.archlinux.org/title/Kernel_mode_setting
* https://en.wikipedia.org/wiki/Mode_setting

## EDID

* https://wiki.archlinux.org/title/Kernel_mode_setting#Forcing_modes_and_EDID

## grub

* [nomodeset-quiet-splash](https://microsin.net/adminstuff/xnix/nomodeset-quiet-splash-kernel-parameters.html)

## amdgpu

* https://wiki.archlinux.org/title/AMDGPU
* [kernel-lack-ums-support] (https://uchet-jkh.ru/i/otsutstvie-podderzki-ums-v-module-radeon/)

## disabling modesetting

https://wiki.archlinux.org/title/Kernel_mode_setting#Disabling_modesetting

driver=free
i915.modeset=0
radeon.modeset=0
nouveau.modeset=0

nomodeset
The newest kernels have moved the video mode setting into the kernel.
So all the programming of the hardware specific clock rates and registers on the video card happen in the kernel rather than in the X driver when the X server starts.
This makes it possible to have high resolution nice looking splash (boot) screens and flicker free transitions from boot splash to login screen.
Unfortunately, on some cards this doesnt work properly and you end up with a black screen.
Adding the nomodeset parameter instructs the kernel to not load video drivers and use BIOS modes instead until X is loaded.

Note that this option is sometimes needed for nVidia cards when using the default "nouveau" drivers.
Installing proprietary nvidia drivers usually makes this option no longer necessary, so it may not be needed to make this option permanent, 
just for one boot until you installed the nvidia drivers.

iommu=soft
pci=noats
acpi=off
https://forum.garudalinux.org/t/cant-boot-on-integrated-radeon-gpu/14890
radeon.si_support=0 radeon.cik_support=0 amdgpu.si_support=1 amdgpu.cik_support=1 modprobe.blacklist=radeon

## misc

* https://www.youtube.com/watch?v=ebbA4jcFO5Q
* https://www.youtube.com/watch?v=Y1zZm8MHbyo
* https://forum.manjaro.org/t/manjaro-live-usb-does-not-start-after-grub/101228/23?page=2

driver=free
acpi=off
noapic

/etc/default/grub
GRUB_CMDLINE_LINUX_DEFAULT=...

recordfail
load_video
gfxmode $linux_gfx_mode
insmod gzio
...
set root='hd0,...'

$vt_handoff 
(vt = virtualterminal) is a kernel boot parameter unique to Ubuntu, and is not an upstream kernel boot parameter.
Its purpose is to allow the kernel to maintain the current contents of video memory on a virtual terminal.

* https://community.frame.work/t/resolved-linux-wont-start-on-amd-without-nomodeset/42220/4
journalctl -k -b-1 > journal.txt


## issues

* https://github.com/linuxdeepin/developer-center/issues/1699#issuecomment-1751777166

## to-read

* https://linuxmint.com.ru/viewtopic.php?p=83892#p83892
* https://www.reddit.com/r/pop_os/comments/qyfh7s/cant_boot_without_nomodeset_with_amd_gpu_stuck_at/
* https://bbs.archlinux.org/viewtopic.php?id=292265
* https://salsa.debian.org/tails-team/tails/blob/master/config/chroot_local-includes/usr/share/initramfs-tools/hooks/kms
* https://forum.puppylinux.com/viewtopic.php?t=2010
* https://losst.pro/ispravlyaem-chernyj-ekran-ubuntu
* https://wiki.astralinux.ru/pages/viewpage.action?pageId=23199819
