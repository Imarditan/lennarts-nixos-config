{ config, ... }:
let
  hostname = config.networking.hostName;
in
{
  system.autoUpgrade = {
    enable = true;
    flake = ''github:zebreus/nixos-config#${hostname}'';
    flags = [
      "--update-input"
      "nixpkgs"
      "--no-write-lock-file"
      "-L" # print build logs
    ];
    dates = "03:20";
    randomizedDelaySec = "5min";
    allowReboot = true;
  };

  nix.optimise = {
    automatic = true;
    dates = [
      "04:40"
    ];
  };

  nix.gc = {
    automatic = true;
    dates = [
      "04:00"
    ];
  };
}
