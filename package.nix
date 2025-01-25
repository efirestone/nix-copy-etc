{ stdenv, system }:

derivation {
  name = "copy-to-etc";
  builder = "/bin/sh";
  args = [ "-c" "echo hello world > $out" ];
  inherit system;
}
