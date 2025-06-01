# MJ's Nix configuration

Hi, I'm MJ (@mjm:midna.dev on Matrix), and this is my Nix config repo.
It holds all the code to provision the various servers and workstations I use.
It's public both for my own convenience and because it allows others to use it as a resource.
I'm not sure if I'm always a good person to copy from, but if you want to, you certainly can.

## Background

When I first created this repo, I used [Misterio77's nix-config](https://m7.rs/git/nix-config/) as my inspiration.
You'll probably see some similarities in structure to what he uses.
However, it's also probably drifted quite a bit into doing things my own way.
Anyway, thanks Gabriel for the helpful inspiration!

## Repo structure

- [hosts](hosts/): Configurations specific for each host
- [lib](lib/): Nix library functions for various purposes
- [modules](modules/): Custom modules for extending various things that use the NixOS module system
- [packages](packages/): Nix packages that for whatever reason aren't upstreamed to Nixpkgs
- [services](services/): Modules for setting up NixOS services, which can be enabled in individual host configs

See the READMEs for individual directories for more details.

## Adding the first host

If you're starting fresh with this configuration on a new system without any existing OS, here's how to get started:

### 1. Boot from NixOS installer

Download and boot from the [NixOS installer ISO](https://nixos.org/download.html). You can create a bootable USB drive using tools like `dd`, Rufus, or Balena Etcher.

### 2. Prepare the system

Once booted into the installer:

```bash
# Connect to the internet (if using WiFi)
sudo systemctl start wpa_supplicant
wpa_cli
> add_network
> set_network 0 ssid "YourWiFiName"
> set_network 0 psk "YourWiFiPassword"
> enable_network 0
> quit

# Partition your disk (example for /dev/sda)
sudo fdisk /dev/sda
# Create partitions as needed (EFI boot, swap, root)

# Format partitions
sudo mkfs.fat -F 32 /dev/sda1  # EFI boot partition
sudo mkswap /dev/sda2          # Swap partition
sudo mkfs.ext4 /dev/sda3       # Root partition

# Mount partitions
sudo mount /dev/sda3 /mnt
sudo mkdir -p /mnt/boot
sudo mount /dev/sda1 /mnt/boot
sudo swapon /dev/sda2
```

### 3. Generate initial configuration

```bash
# Generate hardware configuration
sudo nixos-generate-config --root /mnt

# Clone this repository
nix-shell -p git
git clone https://github.com/C1oover/nix-config-mjm.git /mnt/etc/nixos/nix-config
```

### 4. Create your host configuration

```bash
cd /mnt/etc/nixos/nix-config

# Create a new host directory (replace 'myhost' with your desired hostname)
mkdir -p hosts/myhost

# Copy the generated hardware configuration
cp /mnt/etc/nixos/hardware-configuration.nix hosts/myhost/

# Create a basic host configuration
cat > hosts/myhost/default.nix << 'EOF'
{ inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "myhost";

  # Enable basic desktop environment (optional)
  mjm.desktop.enable = true;

  # Enable SSH for remote access
  services.openssh.enable = true;

  # Set your state version (check https://nixos.org/manual/nixos/stable/release-notes.html)
  system.stateVersion = "24.05";
}
EOF
```

### 5. Update plans.nix

Add your new host to the configuration:

```bash
# Edit plans.nix to include your new host
# Add "myhost" to the hostNames list
```

### 6. Install NixOS

```bash
# Install NixOS with your configuration
sudo nixos-install --flake /mnt/etc/nixos/nix-config#myhost

# Set root password when prompted
# Reboot
sudo reboot
```

### 7. Post-installation setup

After rebooting into your new system:

```bash
# Clone the config to your user directory for easier management
git clone https://github.com/C1oover/nix-config-mjm.git ~/nix-config
cd ~/nix-config

# Make any additional configuration changes
# Rebuild the system
sudo nixos-rebuild switch --flake .#myhost
```

### Notes

- Replace `myhost` with your desired hostname throughout the process
- Adjust partition sizes and filesystem types based on your needs
- The example uses a simple partitioning scheme; you may want to use LVM, LUKS encryption, or other advanced setups
- Make sure to update the `hostNames` list in `plans.nix` to include your new host
- Consider setting up secrets management if you need encrypted configuration values
