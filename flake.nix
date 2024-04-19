{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    norg.url = "github:nvim-neorg/tree-sitter-norg/dev";
    norg-meta.url = "github:nvim-neorg/tree-sitter-norg-meta";

    neorg = {
      url = "github:nvim-neorg/neorg";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    norg,
    norg-meta,
    neorg,
  }: {
    overlays.default = final: prev: let
      inherit (final.lib) attrValues elemt filter filterAttrs isDerivation;
    in {
      vimPlugins = prev.vimPlugins.extend (f: p: {
        neorg = final.vimUtils.buildVimPlugin {
          pname = "neorg";
          version = "v7.0.0";
          src = neorg;
        };
      });
    };
  };
}
