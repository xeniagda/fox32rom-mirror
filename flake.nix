{
  description = "fox32rom";

  inputs = {
    fox32asm.url = "git+https://githug.xyz/xenia/fox32asm";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, fox32asm, flake-utils }:
    flake-utils.lib.eachDefaultSystem (sys:
      let pkgs = nixpkgs.legacyPackages.${sys};
          asm = fox32asm.packages.${sys}.default;
          fox32rom = pkgs.runCommand "fox32rom" {} ''
            cp -r ${./.}/* ./
            mkdir -p $out/{bin,dev}
            ${asm}/bin/fox32asm ./main.asm $out/bin/fox32.rom
            cp ${./fox32rom.def} $out/dev/fox32rom.def
          '';

          fox32rom-dev = pkgs.runCommand "fox32rom-dev" {} ''
            mkdir -p $out/dev
            cp ${./fox32rom.def} $out/dev/fox32rom.def
          '';

      in rec {
        packages.fox32rom = fox32rom;
        packages.fox32rom-dev = fox32rom-dev;
        packages.default = fox32rom;

        devShells.default = pkgs.mkShell {
          packages = [ asm ];
        };
      }
    );
}
