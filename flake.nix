{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = inputs: let
    system = "x86_64-linux";
    pkgs = import inputs.nixpkgs {inherit system;};
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [
        ocamlPackages.ocaml-lsp
        ocamlPackages.ocamlformat
        ocamlPackages.dune_3
        ocaml
      ];
    };

    packages.${system}.default = pkgs.ocamlPackages.buildDunePackage {
      pname = "discaml";
      version = "0.1";
      src = ./.;
    };

    homeManagerModules = {
      default = import ./module.nix inputs;
    };
  };
}
