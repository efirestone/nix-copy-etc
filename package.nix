{ stdenv, system }:

# derivation {
#   name = "file-permissions";
#   builder = "/bin/sh";
#   args = [ "-c" "stat -c \"%a\" ${file} > $out" ];
#   inherit system;
# }

# derivation {
#   name = "file-permissions";
#   builder = "/bin/sh";
#         args = [ stat -c "%a" ${file} > $out
#       '';
# }