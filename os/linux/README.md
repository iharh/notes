# reparing

## login

```
$ sudo systemctl disable lightdm.service
Synchronizing state of lightdm.service with SysV service script with /usr/lib/systemd/systemd-sysv-install.
Executing: /usr/lib/systemd/systemd-sysv-install disable lightdm
Removed "/etc/systemd/system/display-manager.service".

$ sudo systemctl enable --now lightdm.service
$ sudo dpkg-reconfigure lightdm

$ sway -d --unsupported-gpu

Mar 31 20:43:25 EPBYGOMW0024T2 systemd[1]: Started greetd.service - Greeter daemon.
Mar 31 20:43:25 EPBYGOMW0024T2 greetd[1642]: PAM unable to dlopen(pam_lastlog.so): /usr/lib/security/pam_lastlog.so: cannot open shared object file: No such file or directory
Mar 31 20:43:25 EPBYGOMW0024T2 greetd[1642]: PAM adding faulty module: pam_lastlog.so
```

## pam

```
$ dpkg -L login
...
/etc/pam.d/login
...
82:session    optional   pam_lastlog.so
```
pam_lastlog: deprecate it and disable by default
* https://github.com/linux-pam/linux-pam/commit/357a4ddbe9b4b10ebd805d2af3e32f3ead5b8816

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

## lshw

❯ sudo lshw -c video
  *-display UNCLAIMED       
       description: VGA compatible controller
       product: Cezanne [Radeon Vega Series / Radeon Vega Mobile Series]
       vendor: Advanced Micro Devices, Inc. [AMD/ATI]
       physical id: 0
       bus info: pci@0000:06:00.0
       version: c8
       width: 64 bits
       clock: 33MHz
       capabilities: pm pciexpress msi msix vga_controller bus_master cap_list
       configuration: latency=0
       resources: memory:d0000000-dfffffff memory:e0000000-e01fffff ioport:e000(size=256) memory:fcb00000-fcb7ffff memory:c0000-dffff

## UMS/KMS

* https://en.wikipedia.org/wiki/Mode_setting
* https://wiki.archlinux.org/title/Kernel_mode_setting
* https://wiki.archlinux.org/title/Kernel_mode_setting#Forcing_modes_and_EDID

## grub

* [nomodeset-quiet-splash](https://microsin.net/adminstuff/xnix/nomodeset-quiet-splash-kernel-parameters.html)

```
$ info -f grub -n 'Simple configuration'
$ sudo dpkg-reconfigure grub-pc
$ sudo dpkg-reconfigure grub-common
$ sudo debconf-show grub-pc
...
$ sudo update-grub

$ dpkg -L grub-common
/etc/default/grub.d
/etc/grub.d/00_header
/etc/grub.d/05_debian_theme
/etc/grub.d/10_linux
/etc/grub.d/10_linux_zfs
/etc/grub.d/20_linux_xen
/etc/grub.d/25_bli
/etc/grub.d/30_os-prober
/etc/grub.d/30_uefi-firmware
/etc/grub.d/40_custom
/etc/grub.d/41_custom
/etc/grub.d/README
/etc/init.d/grub-common
/etc/pm/sleep.d/10_grub-common
/lib
diverted by base-files to: /lib.usr-is-merged
/lib/systemd/system/grub-initrd-fallback.service

$ cat /etc/default/grub.d/timeout
GRUB_TIMEOUT=5
GRUB_TIMEOUT_STYLE="countdown"
GRUB_TERMINAL=console
```



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

```

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
```

## dkms

```
$ sudo dkms autoinstall
```

## internals

* https://www.linux.org.ru/forum/general/4221448

0 - switch KMS off if it is not supported by xf86-video-ati/radeon

drivers/gpu/radeon/radeon_drv.c
* https://github.com/torvalds/linux/blob/master/drivers/gpu/drm/radeon/radeon_drv.c

## misc 1

* https://www.linuxquestions.org/questions/linux-hardware-18/how-to-permanently-load-radeon-driver-4175695012/

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


* https://forum.garudalinux.org/t/amd-7900xtx-live-usb/26303
* https://forum.garudalinux.org/t/amd-7900xtx-live-usb/26303/3
    Currently the new AMD 7900XTX graphics card needs llvm-libs version 15 or higher to boot. All live USB ISO files are version 14.
* https://forum.garudalinux.org/t/amd-7900xtx-live-usb/26303/4
    So, I googled the issue and it appears to be a problem for almost all distros and their live USB with the exception of Fedora and one other. 
    llvm-libs needs to be version 15 or better and not 14.
* https://forum.garudalinux.org/t/amd-7900xtx-live-usb/26303/13
    https://forum.garudalinux.org/u/dr460nf1r3/summary
    https://forum.garudalinux.org/u/dr460nf1r3/activity
* https://forum.garudalinux.org/t/call-for-testers-of-our-new-major-release-builds/35597

## recovery console

* [recovery-console](https://wiki.astralinux.ru/pages/viewpage.action?pageId=27361474)

## plymouth

plymouth-start.service

## mesa

fedora sway[1275]: MESA-LOADER: failed to open simpledrm: /usr/lib64/dri/simpledrm_dri.so: cannot open shared object file: No such file or directory (search paths /usr/lib64/dri, suffix _dri)

* https://github.com/swaywm/sway/issues/7767

You need to install mesa-dri-gallium to have radeonsi or radv, the firmware is not the userland driver.
    mesa-dri-gallium
    ? mesa-dri-drivers
simpledrm is the kernel default framebuffer driver when no gpu is available.

??? /lib/firmware/vendor

## amdgpu

* https://forum.garudalinux.org/t/not-able-to-execute-this-command-sudo-echo-balanced-sys-class-drm-card0-device-power-dpm-state/12185
* https://forum.garudalinux.org/t/amdgpu-driver-issue-gpu-crashes-on-reaching-400mhz-core-clock-speeds-amd-radeon-r5-m330-430/11972
* https://www.reddit.com/r/archlinux/comments/pelxaw/amdgpu_driver_issue/

## loglevel

* https://stackoverflow.com/questions/16390004/change-default-console-loglevel-during-boot-up

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
