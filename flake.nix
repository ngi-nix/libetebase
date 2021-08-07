{
  description = "A C library for Etebase";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-21.05";

  outputs = { self, nixpkgs }:
    let

      # Generate a user-friendly version numer.
      version = builtins.substring 0 8 self.lastModifiedDate;

      # System types to support.
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });

    in

    {

      # A Nixpkgs overlay.
      overlay = final: prev: {

        libetebase = with final; stdenv.mkDerivation rec {
          name = "libetebase-${version}";

          src = ./.;

          cargoDeps = rustPlatform.fetchCargoTarball{
            inherit src;
            hash = "sha256-yBaKoCHgIFpskcixYaq4ZYfS14g9DyvT2DWUllhK3zY="; 
          };
          
          buildInputs = [ rustc cargo openssl libsodium ];

          nativeBuildInputs = [ pkg-config ];

        };

      };

      # Provide some binary packages for selected system types.
      packages = forAllSystems (system:
        {
          inherit (nixpkgsFor.${system}) libetebase;
        });

      # The default package for 'nix build'. This makes sense if the
      # flake provides only one package or there is a clear "main"
      # package.
      defaultPackage = forAllSystems (system: self.packages.${system}.libetebase);

    };
}
