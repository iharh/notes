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

## grub

* [nomodeset-quiet-splash](https://microsin.net/adminstuff/xnix/nomodeset-quiet-splash-kernel-parameters.html)

## amdgpu

* [kernel-lack-ums-support] (https://uchet-jkh.ru/i/otsutstvie-podderzki-ums-v-module-radeon/)
