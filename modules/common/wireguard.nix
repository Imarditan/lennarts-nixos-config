{ config, lib, ... }:
let
  thisMachine = config.machines."${config.networking.hostName}";
  isServer = thisMachine.staticIp4 != null;
  # If this is a server: All other machines including servers and clients
  # If this is a client: Only other machines that are servers
  otherMachines = lib.attrValues (lib.filterAttrs (name: machine: name != config.networking.hostName && (isServer || (machine.staticIp4 != null))) config.machines);
in
{
  imports = [
    ../machines.nix
  ];

  age.secrets.wireguard_private_key = {
    file = ../../secrets + "/${config.networking.hostName}_wireguard.age";
    mode = "0444";
  };
  age.secrets.shared_wireguard_psk = {
    file = ../../secrets/shared_wireguard_psk.age;
    mode = "0444";
  };

  networking = {
    # Open firewall port for WireGuard.
    firewall = {
      allowedUDPPorts = [ 51820 ];
    };

    # Add all machines to the hosts file.
    hosts = builtins.listToAttrs (builtins.map
      (machine: {
        name = "10.20.30.${builtins.toString machine.address}";
        value = [ "${machine.name}.antibuild.ing" machine.name ];
      })
      (lib.attrValues config.machines));

    # Prevent networkmanager from doing weird stuff with the wireguard interface.
    networkmanager =
      lib.mkIf config.networking.networkmanager.enable {
        unmanaged = [ "antibuilding" ];
      };

    # Configure the WireGuard interface.
    wireguard.interfaces = {
      # "antibuilding" is the network interface name.
      antibuilding = {
        ips = [ "10.20.30.${builtins.toString thisMachine.address}/24" ];
        listenPort = 51820;

        # Path to the private key file.
        privateKeyFile = config.age.secrets.wireguard_private_key.path;

        peers = builtins.map
          (machine: (
            {
              name = machine.name;
              publicKey = machine.wireguardPublicKey;
              presharedKeyFile = config.age.secrets.shared_wireguard_psk.path;
              # Send keepalives every 25 seconds.
              persistentKeepalive = 25;
            } //
            (if machine.staticIp4 == null then {
              allowedIPs = [ "10.20.30.${builtins.toString machine.address}/32" ];
            } else {
              allowedIPs = [ "10.20.30.0/24" ];

              # Set this to the server IP and port.
              endpoint = "${machine.staticIp4}:51820";
            })
          ))
          otherMachines;
      };
    };
  };

  # Enable IP forwarding on the server so peers can communicate with each other.
  boot =
    if isServer then {
      kernel.sysctl."net.ipv4.conf.antibuilding.forwarding" = isServer;
    } else { };
}