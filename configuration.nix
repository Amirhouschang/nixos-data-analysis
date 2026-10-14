# WARNING: Do not use this configuration blindly. Check every tool yourself before you adopt it.

# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "de";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "de";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.amir = {
    isNormalUser = true;
    description = "Amir";
    extraGroups = [ "networkmanager" "wheel" "docker"];
    packages = with pkgs; [
      kdePackages.kate
    #  thunderbird
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
    git
    vscode
    brave
    dbeaver-bin            # SQL client for PostgreSQL, SQLite, MySQL etc.
    libreoffice-qt
    discord
    thunderbird
    proton-vpn
    proton-pass
    github-desktop
    kdePackages.tokodon    # Mastodon client for KDE
    tor-browser
    ollama                 # CLI client; models run on the host (see OLLAMA_HOST)
    zoom-us
    teams-for-linux        # unofficial Microsoft Teams client
    duckdb                 # run SQL directly on CSV/Parquet files in the terminal
    sqlitebrowser          # GUI for SQLite databases
    gh                     # GitHub CLI
    obsidian               # Markdown notes
    htop                   # process and resource monitor
    btop                   # modern resource monitor with graphs
    # onlyoffice-desktopeditors   # optional: remove "#" to enable
    (python3.withPackages (ps: with ps; [
      # Core data analysis
      pandas numpy matplotlib seaborn plotly scikit-learn
      jupyterlab ipykernel requests
      scipy                # statistical tests and scientific computing
      statsmodels          # regression and time series models
      pyarrow              # Parquet files (faster and smaller than CSV)
      tqdm                 # progress bars for long loops
      python-dotenv        # load API keys from a .env file

      # Databases
      duckdb               # fast in-process SQL engine
      psycopg              # PostgreSQL driver
      sqlalchemy           # database toolkit / ORM

      # Excel files
      openpyxl             # read/write .xlsx
      xlrd                 # read old .xls

      # Data collection
      yfinance             # stock and market data from Yahoo Finance
      feedparser           # RSS/Atom feeds
      trafilatura          # extract main text from web pages
      beautifulsoup4       # HTML parsing / web scraping
      google-api-python-client  # Google APIs (e.g. YouTube Data API)
      azure-identity       # authentication for Microsoft Azure services
      telethon             # Telegram API client
      (toPythonModule instaloader)  # Instagram data collection

      # Dashboards and GUI
      streamlit            # interactive web dashboards
      pyside6              # Qt desktop GUI

      # Text mining / NLP
      nltk                 # natural language toolkit
      gensim               # topic modelling and word embeddings
      fasttext             # text classification and language detection
      flashtext            # fast keyword search and replacement
      python-crfsuite      # sequence labelling (used by Persian NLP tools)
      wordcloud            # word clouds
      networkx             # network analysis

      # Dates and misc
      jdatetime            # Persian (Jalali) calendar
      pytz                 # time zones
      qrcode               # generate QR codes
    ]))
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?
  services.spice-vdagentd.enable = true;
  services.qemuGuest.enable = true;
    virtualisation.docker = {
    enable = true;
    package = pkgs.docker_29;
  };
   services.open-webui = {
    enable = true;
    environment = {
      OLLAMA_BASE_URL = "http://192.168.122.1:11434";
      SCARF_NO_ANALYTICS = "True";
      DO_NOT_TRACK = "True";
      ANONYMIZED_TELEMETRY = "False";
    };
  };
  # --- Local AI without a host (when NixOS is the main OS) ---
  # 1. Remove environment.variables.OLLAMA_HOST and OLLAMA_BASE_URL in this file
  # 2. Remove "#" from the lines below
  # 3. Choose the package for your GPU: ollama-rocm (AMD) or ollama-cuda (NVIDIA)
  # services.ollama = {
  #   enable = true;
  #   package = pkgs.ollama-rocm;
  # };
    services.postgresql = {
    enable = true;
    ensureDatabases = [ "amir" ];
    ensureUsers = [
      { name = "amir"; ensureDBOwnership = true; }
    ];
  };
    environment.variables.OLLAMA_HOST = "http://192.168.122.1:11434";
    fileSystems."/home/amir/share" = {
    device = "share";
    fsType = "virtiofs";
    options = [ "nofail" ];
  };
  services.openssh.enable = true;
  services.n8n.enable = true;
  services.openssh.settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
  };
  networking.firewall.enable = true;  # enabled by default, set explicitly for clarity
}


