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

* https://wiki.astralinux.ru/pages/viewpage.action?pageId=1212473

## initramfs

* https://wiki.astralinux.ru/pages/viewpage.action?pageId=1212473

/etc/modprobe.d/blacklist.conf
...
blacklist radeon
options radeon modeset=0

initramfs-tools:
    /etc/initramfs-tools/conf.d
    /etc/initramfs-tools/update-initramfs.conf
    /etc/kernel/postinst.d/initramfs-tools
    /etc/kernel/postrm.d/initramfs-tools
    /usr/sbin/update-initramfs
    /usr/share/lintian/overrides/initramfs-tools
    /usr/share/man/man5/update-initramfs.conf.5.gz
    /usr/share/man/man8/update-initramfs.8.gz

```
$ cat /etc/initramfs-tools/modules 
# delete line
radeon modeset=1
```
```
$ update-initramfs -u -k all
```

```
$ tree /etc/initramfs-tools
/etc/initramfs-tools/
    conf.d/
        calamares-safe-initramfs.conf
        cryptsetup
    hooks/
    initramfs.conf
    modules
    scripts/
        init-bottom
        init-premount
        init-top
        local-bottom
        local-premount
        local-top
        nfs-bottom
        nfs-premount
        nfs-top
        panic
    update-initramfs.conf
```

```
$cat /usr/sbin/update-initramfs
...
BOOTDIR=/boot
CONF=/etc/initramfs-tools/update-initramfs.conf
...
get_sorted_versions()
{
	version_list="$(
		linux-version list |
		while read -r version; do
		      test -e "${BOOTDIR}/initrd.img-$version" && echo "$version"
		done |
		linux-version sort --reverse
		)"
	verbose "Available versions: ${version_list}"
}

set_current_version()
{
	if [ -f "/boot/initrd.img-$(uname -r)" ]; then
		version=$(uname -r)
	fi
}
...
# Invoke bootloader
run_bootloader()
{
	# invoke policy conformant bootloader hooks
	if [ -d /etc/initramfs/post-update.d/ ]; then
		run-parts --arg="${version}" --arg="${initramfs}" \
			/etc/initramfs/post-update.d/
		return 0
	fi
}
...
```

## modprobe

kmod: /etc/modprobe.d/blacklist.conf

tree /etc/modprobe.d
/etc/modprobe.d
├── alsa-base.conf
├── blacklist-ath_pci.conf
├── blacklist.conf
├── blacklist-firewire.conf
├── blacklist-framebuffer.conf
├── blacklist-modem.conf
├── blacklist-oss.conf -> /lib/linux-sound-base/noOSS.modprobe.conf
├── blacklist-radeon.conf
├── blacklist-rare-network.conf
├── dkms.conf
└── iwlwifi.conf


$ dpkg -L kmod
/etc/depmod.d/ubuntu.conf
/etc/init.d/kmod
/etc/modprobe.d/blacklist-ath_pci.conf
/etc/modprobe.d/blacklist-firewire.conf
/etc/modprobe.d/blacklist-framebuffer.conf
/etc/modprobe.d/blacklist-rare-network.conf
/etc/modprobe.d/blacklist.conf
/etc/modprobe.d/iwlwifi.conf
/usr/bin/kmod
/usr/lib/modprobe.d/aliases.conf
/usr/sbin
/usr/share
/usr/share/bash-completion/completions
/usr/share/bash-completion/completions/kmod
/usr/share/doc/libkmod2/README.md
/usr/share/doc/libkmod2/TODO
/usr/share/initramfs-tools/hooks/kmod
/usr/share/man/man5/depmod.d.5.gz
/usr/share/man/man5/modprobe.d.5.gz
/usr/share/man/man5/modules.dep.5.gz
/usr/share/man/man8/depmod.8.gz
/usr/share/man/man8/insmod.8.gz
/usr/share/man/man8/kmod.8.gz
/usr/share/man/man8/lsmod.8.gz
/usr/share/man/man8/modinfo.8.gz
/usr/share/man/man8/modprobe.8.gz
/usr/share/man/man8/rmmod.8.gz
/usr/bin/lsmod
/usr/sbin/depmod
/usr/sbin/insmod
/usr/sbin/lsmod
/usr/sbin/modinfo
/usr/sbin/modprobe
/usr/sbin/rmmod
/usr/share/doc/kmod
/usr/share/man/man5/modules.dep.bin.5.gz

## internals

* https://www.linux.org.ru/forum/general/4221448

0 - switch KMS off if it is not supported by xf86-video-ati/radeon

drivers/gpu/radeon/radeon_drv.c
* https://github.com/torvalds/linux/blob/master/drivers/gpu/drm/radeon/radeon_drv.c

## misc 1

https://www.linuxquestions.org/questions/linux-hardware-18/how-to-permanently-load-radeon-driver-4175695012/


```
$ cat /usr/share/X11/xorg.conf.d/00-amdgpu.conf
Section "OutputClass"
        Identifier "AMDgpu"
        MatchDriver "amdgpu"
        Driver "amdgpu"
EndSection

Section "Files"
        ModulePath "/opt/amdgpu-pro/lib/xorg/modules"
        ModulePath "/opt/amdgpu/lib/xorg/modules"
        ModulePath "/usr/lib/xorg/modules"
EndSection

xserver-xorg-amdgpu-video-amdgpu: /usr/share/X11/xorg.conf.d/00-amdgpu.conf

$ dpkg -L xserver-xorg-amdgpu-video-amdgpu
/opt/amdgpu/lib/xorg/modules/drivers/amdgpu_drv.so
/opt/amdgpu/share/man/man4/amdgpu.4
/usr/share/X11/xorg.conf.d/00-amdgpu.conf

$ man amdgpu
$ cat /opt/amdgpu/share/man/man4/amdgpu.4
```

```
$ ls -la /lib/firmware/amdgpu
```

## misc 2

* https://ubuntuforums.org/showthread.php?t=2489555
* https://forum.garudalinux.org/t/cant-boot-on-integrated-radeon-gpu/14890/
* https://forums.opensuse.org/t/12-3-radeon-modeset-boot-problem/87954/
!!!

```
$ sudo update-grub

```

## recovery console

* [recovery-console](https://wiki.astralinux.ru/pages/viewpage.action?pageId=27361474)

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
