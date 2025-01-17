# Enable the GNOME Desktop Environment.
{ pkgs, lib, config, ... }:
{
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };
  services.gnome = {
    tracker.enable = true;
    tracker-miners.enable = true;
  };


  environment.systemPackages = with pkgs;
    [
      gnome.gnome-tweaks
      gnome.dconf-editor
      gnomeExtensions.appindicator
      headsetcontrol
      headset-charge-indicator
    ];

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # GDMs does not work well
  security.pam.services.login.showMotd = lib.mkForce false;
}
