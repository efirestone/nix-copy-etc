{
  config,
  pkgs,
  lib ? pkgs.lib,
  stdenv,
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
    map (file: let
      # filePermissionsScript = stdenv.mkDerivation {
      #   name = "file-permissions";
      #   nativeBuildInputs = [ coreutils ];
      #   runLocal = true;
      #   builder = "/bin/sh";
      #   args = [ "-c" "stat -c \"%a\" ${file} > $out" ];
      #   system = builtins.currentSystem;
      # };
      filePermissionsScript = pkgs.runCommandWith {
        name =  "file-permissions";
        # runLocal = true;
        derivationArgs = {
          # __noChroot = true;
          nativeBuildInputs = [ pkgs.coreutils ];
          system = builtins.currentSystem;
        };
        # system = builtins.currentSystem;
      } ''
        ${pkgs.coreutils}/bin/stat -c "%a" ${file} > $out
      '';
      # filePermissionsScript = builtins.exec ["stat" "-c" "%a" file];
      # filePermissionsScript = lib.readFile "${pkgs.runCommand "stat" { env.file = file; } "stat -c \"%a\" $file > $out"}";

      # filePermissionsScript = pkgs.runCommand "file-permissions" {
      #   __noChroot = true;
      #   preferLocalBuild = true;
      #   allowSubstitutes = false;  # Prevents pulling from binary cache
      # } ''
      #   ${pkgs.coreutils}/bin/stat -c "%a" /nix/store > $out
      # '';
      # mode = builtins.readFile (pkgs.runCommandLocal "file-permissions" {} ''
      #   stat -c "%a" ${file} > $out
      # '');
      # ${if pkgs.stdenv.isDarwin then "stat -f %p" else "stat -c %a"} ${file} > $out
    in {
      mode = builtins.readFile filePermissionsScript;
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
      verbose = lib.mkOption {
        type = types.bool;
        default = false;
        description = "Whether or not to print out which files are being copied over to /etc.";
      };
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
    environment.etc = lib.throwIf (sourceDirs == [])
      "copy-to-etc.sourceDirs must contain at least one entry." etcFiles;

    system.activationScripts.print-etc-files = let
      printableFiles = map(file: "   ${file.value.source} (${file.mode})-> /etc/${file.name}") allFiles;
    in mkIf cfg.verbose {
      text = ''
        echo "Copying /etc files:${"\n"}${builtins.concatStringsSep "\n" printableFiles}";
      '';
    };

    system.activationScripts.print-etc-source-dirs = let
      printableDirs = map(dir: "   ${toString dir}") sourceDirs;
    in mkIf cfg.verbose {
      text = ''
        echo "Copying /etc files from dirs:${"\n"}${builtins.concatStringsSep "\n" printableDirs}";
      '';
    };
  };
}
