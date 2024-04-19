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

    neorg-telescope = {
      url = "github:nvim-neorg/neorg-telescope";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    neorg-telescope,
    norg,
    norg-meta,
    neorg,
  }:
    {
      overlays.default = final: prev: let
        inherit (final.lib) attrValues elem filter filterAttrs isDerivation;
      in {
        vimPlugins = prev.vimPlugins.extend (f: p: {
          nvim-treesitter = let
            norgGrammars = {
              tree-sitter-norg = norg.defaultPackage.${final.system};
              tree-sitter-norg-meta = norg-meta.defaultPackage.${final.system};
            };
            builtGrammars = (filterAttrs (_: isDerivation) p.nvim-treesitter.builtGrammars) // norgGrammars;
            allGrammars = attrValues builtGrammars;
            withPlugins = grammarFn:
              p.nvim-treesitter.withPlugins (
                _: let
                  plugins = grammarFn builtGrammars;
                in
                  plugins ++ (filter (p: !(elem p plugins)) (attrValues norgGrammars))
              );
            withAllGrammars = withPlugins (_: allGrammars);
          in
            p.nvim-treesitter.overrideAttrs (a: {
              passthru = {
                inherit builtGrammars allGrammars withPlugins withAllGrammars;
              };
            });
          neorg = final.vimUtils.buildVimPlugin {
            pname = "neorg";
            version = "v7.0.0";
            src = neorg;
            dependencies = [f.plenary-nvim (f.nvim-treesitter.withPlugins (_: []))];
          };

          neorg-telescope = final.vimUtils.buildVimPlugin {
            pname = "neorg-telescope";
            version = neorg-telescope.rev;
            src = neorg-telescope;
            dependencies = [f.telescope-nvim f.neorg];
          };
        });
      };
      overlay = nixpkgs.lib.warn "`neorg-overlay.overlay` is deprecated; use `neorg-overlay.overlays.default` instead" self.overlays.default;
    }
    // (flake-utils.lib.eachDefaultSystem (system: {
      checks =
        import ./tests.nix
        (import nixpkgs {
          inherit system;
          overlays = [self.overlays.default];
        });
    }));
}
