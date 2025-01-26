# Nix copy-to-etc
Automatically copy files directly from ./etc in your config repo into /etc/ in your nix install

## Summary

Nix provides the [environment.etc](https://search.nixos.org/options?channel=unstable&show=environment.etc) configuration option as a way to create files in the `/etc` directory of the configured Nix install. In many cases, however, you simply want to copy over a file and don't need to configure advanced options for it. In this scenario it's simpler to have the file directly in your configuration repo and have it copied over wholesale. This is where `copy-to-etc` comes in.

## Installation and Usage

To enable this module, add it to your flake configuration:

```
{
  inputs {
    copy-to-etc.url = "github:efirestone/nix-copy-to-etc/0.1.0";
    nixpkgs.url = "nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs, copy-to-etc }: let
    system = "x86_64-linux";
  in {
    nixosConfigurations.myHost = nixpkgs.lib.nixosSystem {
      system = system;
      modules = [
        ./configuration.nix
        copy-to-etc.nixosModules.copy-to-etc
      ];
    };
  };
}
```

and then enable the module:

```
services.copy-to-etc.enable = true;
```

By default, `copy-to-etc` will look for files in the `./etc` directory of your configuration repo, but you can configure one or more different directories instead if you want:

```
services.copy-to-etc.sourceDirs = [ ./tests/etc1 ./tests/etc2 ];
```

## Caveats

### Nix Store

Under the covers this flake is using `environment.etc`, which copies the files into the Nix store, then symlinks them into `/etc`. This means that your files will be unlinked if you remove them from your config (and deploy that config), but they will still be stored in the Nix store until you garbage collect it.

### File Ownership and Permissions

The current version does not attempt to set the permissions or ownership of the files in any way. The defaults provided by `environment.etc` are used.

### Overlapping Files

The current version also does not detect the case where two local directories contain files that will end up at the same path in `/etc`. For example, if you had `./etc1/config.yaml` and `./etc2/config.yaml` and you configured `sourceDirs` to be `[ ./etc1 ./etc2 ]`. In this case the one processed later (the `etc2` one in this case) would be used, but no warning is issued.

