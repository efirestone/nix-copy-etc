{ overlays }:

{
  copy-to-etc = import ./service.nix;

  overlayNixpkgsForThisInstance =
    { pkgs, ... }:
    {
      nixpkgs = {
        inherit overlays;
      };
    };
}
