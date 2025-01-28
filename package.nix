{ stdenv, system }:

derivation {
  name = "copy-to-etc";
  builder = "/bin/sh";
  # args = [ "-c" "stat -c \"%a\" \"foo\" > $out" ];
  inherit system;
  # system = builtins.currentSystem;
}

# derivation {
#   name = "file-permissions";
#   builder = "/bin/sh";
#         args = [ stat -c "%a" ${file} > $out
#       '';
# }