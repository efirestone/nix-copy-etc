{
  config,
  pkgs,
  lib ? pkgs.lib,
  ...
}:

with lib;

# Copy everything from the sourceDirs directories into the /etc/ directory on the remote Nix machine.
let
  cfg = config.services.copy-to-etc;
  sourceDirs = cfg.sourceDirs;

  # Recursive function to collect all files in a directory
  collectFiles = path: builtins.concatLists (map (name:
    let
      subPath = "${path}/${name}";
    in if builtins.readFileType subPath == "directory" then
      collectFiles subPath
    else
      [ subPath ]
  ) (builtins.attrNames (builtins.readDir path)));

  sourceDirsThatExist = builtins.filter (dir: builtins.pathExists dir) sourceDirs;

  # Create a list of entries for all files in all source dirs, where each entry
  # contains the local file path (value) and the path within the Nix install (name).
  allFiles = builtins.concatLists (map (sourceDir:
    map (file: {
      name = builtins.unsafeDiscardStringContext (builtins.substring (builtins.stringLength sourceDir + 1) (builtins.stringLength file) file); # Strip sourceDir prefix
      value = { source = file; };
    }) (collectFiles sourceDir)
  ) sourceDirsThatExist);

  # Convert to environment.etc-compatible structure
  etcFiles = builtins.listToAttrs allFiles;
in {
  options = {
    services.copy-to-etc = rec {
      enable = mkEnableOption "Copy files directly from your config directory to /etc.";
      sourceDirs = lib.mkOption {
        type = types.listOf types.path;
        default = [];
        description = ''
          The directories in the configuration repo which contain files to copy into /etc.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    environment.etc = etcFiles;

    system.activationScripts.print-etc-source-dirs = let
      printableDirs = map(dir: "   ${toString dir}") sourceDirs;
    in {
      text = ''
        echo "Copying /etc files from dirs:${"\n"}${builtins.concatStringsSep "\n" printableDirs}";
      '';
    };

    system.activationScripts.print-etc-files = let
      printableFiles = map(file: "   ${file.value.source} -> /etc/${file.name}") allFiles;
    in {
      text = ''
        echo "Copying /etc files:${"\n"}${builtins.concatStringsSep "\n" printableFiles}";
      '';
    };
  };
}
