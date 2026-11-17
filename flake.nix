{
  description = "Compress, split and extract archives from the CLI";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: rec {
        pkmax = pkgs.stdenv.mkDerivation {
          pname = "pkmax";
          version = "0-unstable-${self.shortRev or self.dirtyShortRev or "dirty"}";
          src = ./.;
          dontBuild = true;
          installPhase = ''
            runHook preInstall
            install -Dm755 packermax.sh $out/bin/pkmax
            install -Dm644 LICENSE $out/share/licenses/pkmax/LICENSE
            runHook postInstall
          '';
          meta = {
            description = "Compress, split and extract archives from the CLI";
            homepage = "https://github.com/Szmelc-INC/PackerMax";
            license = pkgs.lib.licenses.gpl3Only;
            mainProgram = "pkmax";
            platforms = pkgs.lib.platforms.linux;
          };
        };
        default = pkmax;
      });

      apps = forAllSystems (pkgs: {
        default = {
          type = "app";
          program = "${self.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/pkmax";
        };
      });
    };
}
