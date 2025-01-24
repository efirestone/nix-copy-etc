{
  description = "A nix service that copies all files from ./etc (or another directory) in your config repo to /etc in your Nix system.";

  inputs.nixpkgs.url = "nixpkgs/nixos-24.11-small";

  outputs = { self, nixpkgs }:
  let
    forEachSystem = nixpkgs.lib.genAttrs [
      "aarch64-linux"
      "x86_64-linux"
    ];

    overlayList = [ self.overlays.default ];
  in {
    # A Nixpkgs overlay that provides a 'copy-to-etc' package.
    overlays.default = final: prev: { copy-to-etc = final.callPackage ./package.nix {}; };

    packages = forEachSystem (system: {
      copy-to-etc = nixpkgs.legacyPackages.${system}.callPackage ./package.nix {};
      default = self.packages.${system}.copy-to-etc;
    });

    nixosModules = import ./nixos-modules { overlays = overlayList; };

    checks = forEachSystem (system: {
      # To run the tests: nix flake check --all-systems
      # You may also want the -L and --verbose flags for additional debugging.
      multipleSourceDirTest = nixpkgs.legacyPackages.${system}.testers.runNixOSTest {
        name = "multipleSourceDirTest";
        nodes.machine = {
          imports = [ self.outputs.nixosModules.copy-to-etc ];

          # enable our custom module
          services.copy-to-etc.enable = true;
          services.copy-to-etc.sourceDirs = [ ./tests/etc1 ./tests/etc2 ];
        };
        testScript = ''
          machine.wait_for_unit("multi-user.target")
          
          assert machine.execute("cat /etc/config1.txt")[1] == "Configuration 1"
          assert machine.execute("cat /etc/nested/config2.txt")[1] == "Configuration 2"
        '';
      };
    });
  };
}
