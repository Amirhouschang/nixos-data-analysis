# NixOS Data Analysis Workstation

My data analysis system on NixOS 26.05.
One file, `configuration.nix`, installs and configures everything.

> ⚠️ **Do not use this configuration blindly.**
> I built it for my own setup and needs. Check every program, library and service before you use it, remove what you do not need, and change the values listed below for your system.

## Why

- My daily system is Arch Linux (EndeavourOS). I run this setup as a virtual machine on the same laptop with QEMU/KVM and virt-manager.
- Emergency backup: if my Arch system breaks, I can rebuild my programs and services from this one file in about an hour. Personal files, databases, passwords and AI models are not included. They need their own backup.
- I still like NixOS because it is reproducible. The same file rebuilds the same programs and services on another machine. Package versions can be different, because this config does not pin the Nixpkgs version.
- This is useful for people with little Linux experience. If you trust someone's configuration, you do not have to set up everything yourself. But I recommend reading about NixOS or watching some videos first. Do not use other people's configurations blindly, especially if you do not use a VM.

## What's included

| Category | Tools |
|---|---|
| Apps | VS Code, Brave, Firefox, DBeaver, LibreOffice, Obsidian, GitHub Desktop, Zoom, Teams (unofficial), Discord, Thunderbird, Proton VPN, Proton Pass, Tor Browser, Tokodon (Mastodon) |
| Data | Python 3.13 with about 40 libraries (pandas, statsmodels, streamlit, NLP, scraping and more, see the comments in the file), JupyterLab, DuckDB CLI, SQLite Browser |
| Services | PostgreSQL, Docker, Open WebUI (`localhost:8080`), n8n (`localhost:5678`), SSH (key login only), firewall |
| AI | Ollama CLI and Open WebUI, using the models and GPU of the host |
| Terminal | git, gh, htop, btop |

`hardware-configuration.nix` is not included. NixOS creates it during installation.

## Values you must change

| Value in `configuration.nix` | Meaning |
|---|---|
| `amir` | user name (also PostgreSQL user and database) |
| `boot.loader.grub` lines | GRUB on `/dev/vda` for a VM with BIOS firmware. With UEFI keep the bootloader lines from your own generated `configuration.nix`. |
| `192.168.122.1` | the host, seen from the VM (default libvirt network) |
| `/home/amir/share` | shared folder with the host |
| `system.stateVersion` | the NixOS version you installed first. Never change it later. |

---

## Setup

### 1. Host (Arch / EndeavourOS)

```bash
sudo pacman -S qemu-full virt-manager libvirt dnsmasq virtiofsd
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt $USER     # then log out and in again
lsmod | grep kvm                   # must show kvm_amd or kvm_intel
```

This guide also expects on the host:
- Ollama already installed and running (only needed for step 6)
- firewalld running (default on EndeavourOS). On plain Arch: `sudo pacman -S firewalld && sudo systemctl enable --now firewalld`

### 2. Create the VM

```bash
cd ~/Downloads
wget -O nixos-26.05.iso https://channels.nixos.org/nixos-26.05/latest-nixos-graphical-x86_64-linux.iso
mkdir -p ~/Dokumente/share         # shared folder on the host
```

In virt-manager create a new VM with the ISO: 16 GB RAM, 8 CPUs, 150 GB disk.
My first VM had 60 GB and that was too small, because during an update the old and the new packages are on the disk at the same time.
I used BIOS firmware (the virt-manager default on my system). The bootloader lines in `configuration.nix` only fit BIOS.
Tick "Customize configuration before install" and change:

- Memory: enable shared memory
- Video: model Virtio and 3D acceleration
- Display Spice: listen type None and OpenGL
- Add Hardware, Filesystem: driver virtiofs, source `/home/amir/Dokumente/share`, target `share`

### 3. Install NixOS

English, German keyboard, KDE Plasma, allow unfree software, erase disk, ext4, swap. User name `amir`.

### 4. Apply this configuration

Put `configuration.nix` into the shared folder on the host first.
Then type these commands in the VM terminal. Copy and paste into the VM window does not work, see step 5.

```bash
sudo mkdir -p /mnt/share
sudo mount -t virtiofs share /mnt/share
sudo cp /mnt/share/configuration.nix /etc/nixos/
sudo nano /etc/nixos/configuration.nix   # set system.stateVersion to your installed version
sudo nixos-rebuild switch
sudo reboot
```

### 5. SSH: work from the host terminal

In my VM with NixOS 26.05 and Plasma, copy and paste between host and VM window does not work. I also tried the X11 session, but it did not work there either. With NixOS 25.05 on X11 it worked.
My solution: I use the VM from my normal host terminal with SSH. Copy and paste works there.
Password login is disabled, so the key goes through the shared folder.

On the host:
```bash
ssh-keygen -t ed25519                         # press Enter for every question
cp ~/.ssh/id_ed25519.pub ~/Dokumente/share/
```

In the VM:
```bash
mkdir -p ~/.ssh && cat ~/share/id_ed25519.pub >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys
ip -4 addr | grep 192.168                     # write down the IP of the VM
```

On the host (use your IP):
```bash
printf 'Host nixos\n  HostName 192.168.122.23\n  User amir\n' >> ~/.ssh/config
ssh nixos                                     # from now on without password
```

With the default libvirt NAT network the VM is reachable from the host and from other VMs in the same virtual network, but not from your Wi-Fi or the internet. Leave with `exit`.

### 6. Ollama: use the models and GPU of the host

The VM has no real GPU, so Ollama runs on the host. On the host:

```bash
sudo mkdir -p /etc/systemd/system/ollama.service.d
printf '[Service]\nEnvironment="OLLAMA_HOST=0.0.0.0"\n' | sudo tee /etc/systemd/system/ollama.service.d/override.conf
sudo systemctl daemon-reload && sudo systemctl restart ollama
sudo firewall-cmd --zone=libvirt --add-port=11434/tcp --permanent && sudo firewall-cmd --reload
```

- My Ollama comes from the official install script and my models are in `~/.ollama/models`. So I also added `User=amir` and `Group=amir` to the override file.
- Other installations (for example the Arch package) can use another model folder and block access to `/home`. Then `User=` alone is not enough. Check your service with `systemctl cat ollama` first.
- My GPU is integrated (AMD Radeon 890M). Ollama ignores integrated GPUs by default, so I also added `Environment="OLLAMA_IGPU_ENABLE=1"` to the override file. Check with `ollama ps`: the column PROCESSOR must show GPU, not CPU.
- The firewall rule opens the port only for the VM network.

Test in the VM:
```bash
curl http://192.168.122.1:11434/api/tags      # shows the models of the host
ollama list
```
Open WebUI: `http://localhost:8080` in the browser of the VM.

### 7. PostgreSQL password (for DBeaver)

```bash
psql -d amir       # no password needed locally
\password          # type the new password two times
\q
```
DBeaver: PostgreSQL, host `localhost`, port `5432`, database `amir`, user `amir`.

### Using it as main OS (not in a VM)

Without a host from step 6, Ollama must run on NixOS itself. In `configuration.nix`:

- Remove the line `environment.variables.OLLAMA_HOST = …` and the line `OLLAMA_BASE_URL = …`
- Remove the parts only for the VM: `spice-vdagentd`, `qemuGuest` and the `fileSystems."/home/amir/share"` block
- Enable the prepared block "Local AI without a host" (remove the `#`) and choose the package for your graphics card: `ollama-rocm` (AMD) or `ollama-cuda` (NVIDIA)
- NVIDIA also needs a working NVIDIA driver setup. It is not part of this file.
- Keep the bootloader lines from your own generated `configuration.nix`.

If Open WebUI was already used before, it can keep the old connection. Then change the Ollama connection in the Open WebUI admin settings to `http://localhost:11434`.

---

## Daily use

| Task | Command |
|---|---|
| Apply changes in `configuration.nix` | `sudo nixos-rebuild switch` |
| Update everything (security fixes) | `sudo nixos-rebuild switch --upgrade` |
| Remove old versions, free disk space | `sudo nix-collect-garbage -d` |
| Check free disk space | `df -h /` |
| NixOS and kernel version | `nixos-version` and `uname -r` |
| Back up the config to the host | `cp /etc/nixos/configuration.nix ~/share/` |

Add a package: search the name on [search.nixos.org](https://search.nixos.org), add it to the list and rebuild.
If a rebuild fails, the end of the output shows the reason. For example `undefined variable` means a wrong name.

New NixOS release: every May and November. 26.05 gets updates until 31.12.2026.
Run these commands only after NixOS 26.11 is released.
```bash
sudo nix-collect-garbage -d
sudo nix-channel --add https://channels.nixos.org/nixos-26.11 nixos
sudo nixos-rebuild switch --upgrade
```
Do not change `system.stateVersion`.

## Display tips

- In virt-manager: View, Scale Display, Never. Also tick "Auto resize VM with window". Then the picture is sharp.
- If windows feel slow, check that 3D acceleration and OpenGL are enabled (step 2).

## Known limitations

- No copy and paste between host and VM window (NixOS 26.05, Wayland and X11). Use SSH (step 5).
- virt-manager shows only one screen per window.
- No GPU inside the VM, so AI models run on the host.
- Not included yet: `country-converter` (not in Nixpkgs), `llama-index`, `playwright` (planned in a separate Python environment), Superset (planned with Docker, as a Power BI replacement), KNIME.
- No official Linux apps for Power BI, Notion and Proton Drive. I use the web versions.

---

Built with AI assistance. How I use AI in my work: [local-ai-workflow](https://github.com/Amirhouschang/local-ai-workflow)
