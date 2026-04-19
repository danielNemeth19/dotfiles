# Arch Linux Installation Steps (for /dev/nvme0n1)

## 1. Preparation
- Download the latest Arch ISO from [archlinux.org/download](https://archlinux.org/download/).
- Verify the ISO signature (see [official instructions](https://archlinux.org/download/#checksums)).
- Create a bootable USB.
    - `sudo fdisk -l (to see device path of plugged in USB)`
    - `sudo dd bs=4M if=/path/to/file.iso of=/dev/sdX status=progress oflag=sync`
- Boot from USB. Disable Secure Boot if necessary.

## 2. Set Keyboard Layout (if not US)
- List keymaps:  
  `localectl list-keymaps`
- Set Hungarian layout:  
  `loadkeys hu101`

## 3. Verify Boot Mode
- Check UEFI mode:  
  `ls /sys/firmware/efi/efivars`  
  (If present, you are in UEFI mode.)

## 4. Connect to the Internet
- For Ethernet: Plug in cable.
- For Wi-Fi:  
  `iwctl`
- Test:  
  `ping archlinux.org`

## 5. Update System Clock
- `timedatectl set-ntp true`

## 6. Partition Disks
- List disks:  
  `lsblk`
- **Do NOT re-create or format**:
  - EFI: `/dev/nvme0n1p1`
  - Swap: `/dev/nvme0n1p3`
- **Root**: `/dev/nvme0n1p2` (format this)

## 7. Format Partitions
- **EFI:** Only format if you created a new one (not needed here).
- **Swap:** Only initialize if new (not needed here).
- **Root:**  
  - If you want to use ext4:  
    `mkfs.ext4 /dev/nvme0n1p2`
  - If you want to use btrfs:  
    `mkfs.btrfs /dev/nvme0n1p2`

## 8. Mount File Systems
- Mount root:  
  `mount /dev/nvme0n1p2 /mnt`
- Mount EFI:  
  `mount --mkdir /dev/nvme0n1p1 /mnt/boot`
- Enable swap:  
  `swapon /dev/nvme0n1p3`

## 9. Select Mirrors (Optional)
- Edit `/etc/pacman.d/mirrorlist` for fastest mirrors.

## 10. Install Base System
- `pacstrap -K /mnt base linux linux-firmware amd-ucode mesa nvidia nvidia-utils nvidia-prime nvim`
  - `amd-ucode` is needed for AMD chips
    - If you ever switch to an Intel CPU, use `intel-ucode` instead
  - The bootloader (GRUB) will automatically detect and load the microcode update if `amd-ucode` is installed.
  - `mesa`: AMD open-source graphics driver
  - `nvidia`, `nvidia-utils`: NVIDIA proprietary driver and utilities
  - `nvidia-prime`: For PRIME offloading (run apps on NVIDIA GPU with `prime-run`)
- For Vulkan support (optional, for gaming/graphics), Steam or 32-bit apps:
  - `pacstrap -K /mnt vulkan-icd-loader lib32-vulkan-icd-loader lib32-nvidia-utils lib32-mesa`
- For Bluetooth support:
  - `pacstrap -K /mnt bluez bluez-utils`
- For NetworkManager (Wi-Fi/Ethernet auto-connect):
  - `pacstrap -K /mnt networkmanager`

## 11. Fstab
- `genfstab -U /mnt >> /mnt/etc/fstab`
- **Review `/mnt/etc/fstab` for correctness.**

## 12. Chroot
- `arch-chroot /mnt`

## 13. Time Zone
- `ln -sf /usr/share/zoneinfo/Europe/Budapest /etc/localtime`
- `hwclock --systohc`
- **Enable time synchronization:**
  - `systemctl enable systemd-timesyncd`

## 14. Localization
- Edit `/etc/locale.gen` and uncomment `en_US.UTF-8 UTF-8` and/or `hu_HU.UTF-8 UTF-8`
- `locale-gen`
- Create `/etc/locale.conf` with:  
  `LANG=en_US.UTF-8`
- Set keymap in `/etc/vconsole.conf`:  
  `KEYMAP=hu101`

## 15. Network Configuration
- Set your hostname (replace `myhostname` with your desired hostname):
  ```
  echo myhostname > /etc/hostname
  ```

- Configure `/etc/hosts`:
  ```
  127.0.0.1   localhost
  ::1         localhost
  127.0.1.1   myhostname.localdomain myhostname
  ```
  *(Replace `myhostname` with your chosen hostname.)*

- Enable NetworkManager to start at boot:
  ```
  systemctl enable NetworkManager
  ```
- (Optional) Install `network-manager-applet` if you plan to use a graphical desktop.

**After first boot:**  
- To connect to Wi-Fi, use the text-based UI:
  ```
  nmtui
  ```
  - Select "Activate a connection", choose your Wi-Fi network, and enter the password.
  - NetworkManager will remember this network and auto-connect on future boots.

## 16. Bluetooth Setup
- Enable and start Bluetooth service:
  ```
  systemctl enable bluetooth
  systemctl start bluetooth
  ```
- To pair devices, use:
  ```
  bluetoothctl
  ```
  - `power on`
  - `agent on`
  - `scan on`
  - `pair <device MAC>`
  - `connect <device MAC>`
  - `trust <device MAC>`
- For desktop environments, install a Bluetooth tray app (e.g., `blueman` for GTK, `bluedevil` for KDE).

## 17. Initramfs (usually automatic)
- Only needed if you change configs:  
  `mkinitcpio -P`

## 18. Root Password
- `passwd`

## 19. Boot Loader (GRUB, UEFI)
- Install GRUB and efibootmgr:
  ```
  pacman -S grub efibootmgr
  ```
- Install GRUB to the EFI partition:
  ```
  grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
  ```
- Generate the GRUB configuration file:
  ```
  grub-mkconfig -o /boot/grub/grub.cfg
  ```
- (Optional) Verify:
  - You should see `/boot/EFI/GRUB` or `/boot/EFI/Boot/` directories and `/boot/grub/grub.cfg` after these steps.

## 20. Create a User and Configure Sudo
- Install sudo:
  ```
  pacman -S sudo
  ```
- Create your user (replace `yourusername`):
  ```
  useradd -m -G wheel -s /bin/bash yourusername
  passwd yourusername
  ```
- Allow users in the `wheel` group to use sudo:
  - Edit `/etc/sudoers` with `visudo`:
    ```
    visudo
    ```
  - Uncomment the line:
    ```
    %wheel ALL=(ALL:ALL) ALL
    ```
    (Remove the `#` at the start of the line.)

## 21. Exit, Unmount, and Reboot
- Exit chroot:  
  `exit`
- Unmount:  
  `umount -R /mnt`
- Reboot:  
  `reboot`

## 22. Post-Install
- Remove installation media.
- Log in as your user.
- Update the system:
  ```
  sudo pacman -Syu
  ```
- For further setup, see [General Recommendations](https://wiki.archlinux.org/title/General_recommendations).
- If you encounter issues, consult the [Arch Wiki Installation Guide](https://wiki.archlinux.org/title/Installation_guide) and relevant hardware pages.

---

**Summary of partition usage:**
- EFI: `/dev/nvme0n1p1` (reuse, do not format)
- Root: `/dev/nvme0n1p2` (format as desired)
- Swap: `/dev/nvme0n1p3` (reuse, do not format)
````
