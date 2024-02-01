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
            mkdir -p $out/bin
            ${asm}/bin/fox32asm ./main.asm $out/bin/fox32.rom
          '';

      in rec {
        packages.fox32rom = fox32rom;
        packages.default = fox32rom;

        devShells.default = pkgs.mkShell {
          packages = [ asm ];
        };
      }
    );
}
