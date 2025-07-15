# Dataflare Nix Flake

## Install

To install dataflare on NixOS, add the repository to your flake inputs:

```nix
{
  inputs = {
    dataflare = {
      url = "github:hackr-sh/dataflare-nixos-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = {
    # ...outputs
  };
}
```

And then install the package inside your packages:

```nix
home.packages = with pkgs; [
  ...
  inputs.dataflare.packages.x86_64.default
  ...
];

# or 

environment.systemPackages = with pkgs; [
  ...
  inputs.dataflare.packages.x86_64.default
  ...
];
```

## Todo:
- Need to package for ARM based devices (I can't test because I have no ARM Devices)
- Need to support macOS (maybe?)