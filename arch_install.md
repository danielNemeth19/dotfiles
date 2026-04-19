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
  `loadkeys hu`

## 3. Verify Boot Mode
- Check UEFI mode:  
  `ls /sys/firmware/efi/efivars`  
  (If present, you are in UEFI mode.)

## 4. Connect to the Internet
- For Ethernet: Plug in cable.
- For Wi-Fi (using `iwctl`):

  1. Start the interactive tool:
     ```
     iwctl
     ```
  2. List available devices:
     ```
     device list
     ```
  3. Scan for Wi-Fi networks (replace `wlan0` with your device if different):
     ```
     station wlan0 scan
     ```
  4. List available networks:
     ```
     station wlan0 get-networks
     ```
  5. Connect to your network (replace `SSID` with your network name):
     ```
     station wlan0 connect SSID
     ```
     - You will be prompted for the Wi-Fi password if required.

  6. Exit `iwctl`:
     ```
     exit
     ```
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
- **EFI Partition (`/dev/nvme0n1p1`):**
  - Partition doesn't need to be re-created if exists
  - If you want a completely clean boot setup (recommended for single-boot or if you had boot issues), **reformat the EFI partition**:
    ```
    mkfs.fat -F32 /dev/nvme0n1p1
    ```
- **Swap Partition (`/dev/nvme0n1p3`):**
  - Only initialize if new or you want to erase it:
    ```
    mkswap /dev/nvme0n1p3
    ```

- **Root Partition (`/dev/nvme0n1p2`):**
  - Format as desired:
    - For ext4:
      ```
      mkfs.ext4 /dev/nvme0n1p2
      ```
    - For btrfs:
      ```
      mkfs.btrfs /dev/nvme0n1p2
      ```
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
- Enable and start Bluetooth service (start is ignored in chroot!!):
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

**Acer Nitro 5 Notes:**
- Acer firmware may only recognize bootloaders at `/EFI/BOOT/BOOTX64.EFI`. Always copy GRUB there after install.
- If you see only "UEFI Shell" or a null string in BIOS, check that the EFI partition is FAT32, flagged as ESP, and contains `/EFI/BOOT/BOOTX64.EFI`.
- Use the F12 boot menu (enable in BIOS if needed) to select the correct boot device if it does not boot automatically.

**Troubleshooting after reformatting EFI:**
- After reformatting, you must:
- Reinstall the kernel (`pacman -S linux linux-firmware`) after chrooting, because `/boot` will be empty.
- Reinstall GRUB and regenerate the GRUB config.
- Regenerate `/etc/fstab` or update the UUID for `/boot` (EFI) if it changed.
- Copy GRUB to the fallback location for Acer laptops:
  ```
  mkdir -p /boot/EFI/BOOT
  cp /boot/EFI/GRUB/grubx64.efi /boot/EFI/BOOT/BOOTX64.EFI
  ```
- In BIOS, set your HDD/SSD as the first boot device. On Acer Nitro 5, you may need to use the F12 boot menu or manually select the fallback bootloader.

- If you get "dependency failed for /boot" or "timed out waiting for device," update `/etc/fstab` with the new EFI partition UUID or regenerate it:
  ```
  genfstab -U /mnt > /mnt/etc/fstab
  ```
- If GRUB menu is missing Arch Linux, reinstall the kernel and regenerate the GRUB config.




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
- if default shell needs to be fish, then
  ```
  pacman -S fish
  useradd -m -G wheel -s /bin/fish yourusername
  passwd yourusername
  ```

- Allow users in the `wheel` group to use sudo:
  - Edit `/etc/sudoers` with `visudo`:
    ```
    sudo EDITOR=nvim visudo
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
