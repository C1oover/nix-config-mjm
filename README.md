# MJ's Nix configuration

Hi, I'm Cloover (@cloover:midna.dev on Matrix), and this is my Nix config repo.
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
git clone https://github.com/C1oover/nix-config-cloover.git /mnt/etc/nixos/nix-config
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
  cloover.desktop.enable = true;

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
git clone https://github.com/C1oover/nix-config-cloover.git ~/nix-config
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

## Deployment-Specific Configuration Parameters

When adapting this configuration for your own use, you'll need to customize several deployment-specific parameters. This section provides a comprehensive list of all the settings that need to be changed:

### Core Identity Settings

**User Configuration**:
- `modules/common/base/user.nix`: Change default username from "matt" to your username
- `modules/home-manager/git/default.nix`: Update `userEmail` from "matt@mattmoriarity.com"
- `modules/home-manager/work/default.nix`: Update work email if applicable

**Domain and Network**:
- Replace all instances of `midna.dev` with your domain:
  - Authentication: `auth.midna.dev` → `auth.yourdomain.com`
  - Vault: `vault.midna.dev` → `vault.yourdomain.com`
  - Attic cache: `attic.midna.dev` → `attic.yourdomain.com`
  - Git server: `git.midna.dev` → `git.yourdomain.com`
  - Monitoring: `graphs.midna.dev` → `graphs.yourdomain.com`
  - Shell sync: `atuin.midna.dev` → `atuin.yourdomain.com`
  - Links service: `links.midna.dev` → `links.yourdomain.com`

**SSH Configuration**:
- `modules/common/ssh.nix`: Update SSH host patterns from `*.home.mattmoriarity.com`
- `modules/home-manager/homelab/default.nix`: Update SSH principals from "matt,cloover" to your usernames
- Update IP addresses in SSH match patterns (currently `5.78.46.61,152.53.116.186`)

### Service-Specific Settings

**Email Configuration**:
- `modules/home-manager/email.nix`: Update email addresses and aliases
- `services/authelia/default.nix`: Update sender email from "admin@mattmoriarity.com"
- `services/icloudpd/default.nix`: Update iCloud email if using iCloud sync

**Matrix/Chat Services**:
- `services/matrix-server/`: Update Matrix user IDs from "@cloover:midna.dev"
- `services/matrix-server/mautrix-imessage.nix`: Update macOS user path from "/Users/cloover/"

**Backup Configuration**:
- `modules/nixos/backups.nix`: Update S3 bucket from "cloover-restic-backups" to your bucket
- Update Backblaze B2 endpoint if using different provider
- Configure backup encryption keys and credentials

**SPIFFE/Security**:
- `packages/spiffe-tool/shell.nix`: Update trust domain from "spiffe://dev.users.midna.dev"
- Throughout the codebase: Update SPIFFE URIs from "spiffe://home.mattmoriarity.com"
- `services/spire/`: Update all SPIFFE trust domains and service identifiers

### Infrastructure Settings

**Binary Cache**:
- `modules/common/base/attic.nix`: Update Attic cache URL and signing keys
- Configure your own binary cache if desired

**Monitoring and Observability**:
- `modules/home-manager/firefox/search.nix`: Update Grafana URLs
- Configure your own monitoring endpoints

**Git and Development**:
- `modules/home-manager/git/default.nix`: Update Git server URLs
- `services/gitlab-runner/`: Update CI/CD configuration for your repositories

**Service Authentication**:
- `services/linkding/default.nix`: Update superuser name from "cloover"
- `services/authelia/`: Update authentication configuration
- Update all service-specific usernames and credentials

### Security and Secrets

**Certificates and Keys**:
- Generate new SSH host and client certificates for your infrastructure
- Update Vault configuration with your own PKI
- Configure TLS certificates for your domain

**API Keys and Tokens**:
- `packages/launchpad/shell.nix`: Configure your own API tokens
- Update all service-specific API keys and secrets
- Configure OAuth/OIDC providers for your domain

**Database Configuration**:
- Update database connection strings and credentials
- Configure backup and replication settings

### Network and Connectivity

**Consul Service Discovery**:
- `services/consul/`: Update cluster configuration
- Configure service discovery for your network topology

**Ingress and Load Balancing**:
- `services/ingress/`: Update ingress rules for your services
- Configure SSL/TLS termination

**VPN and Tunneling**:
- Update Ghostunnel and service mesh configuration
- Configure network policies and firewall rules

### Customization Checklist

Before deploying, ensure you've updated:

- [ ] All domain references (`midna.dev` → your domain)
- [ ] User names and email addresses
- [ ] SSH keys and certificates
- [ ] SPIFFE trust domains and service identifiers
- [ ] Backup storage configuration (S3 buckets, credentials)
- [ ] Binary cache URLs and signing keys
- [ ] Matrix/chat service user IDs
- [ ] Database connection strings
- [ ] API keys and authentication tokens
- [ ] Monitoring and observability endpoints
- [ ] Git repository URLs
- [ ] Network IP addresses and host patterns
- [ ] Service-specific usernames and credentials

### Testing Your Configuration

After making these changes:

1. **Syntax check**: Run `nix flake check` to verify configuration syntax
2. **Build test**: Test build with `nixos-rebuild build --flake .#persephone`
3. **Dry run**: Use `nixos-rebuild dry-activate` to preview changes
4. **Gradual deployment**: Enable services incrementally to isolate issues
5. **Backup**: Ensure you have backups before applying major changes

This configuration is highly personalized and integrated. Take time to understand each component before adapting it to your environment.
