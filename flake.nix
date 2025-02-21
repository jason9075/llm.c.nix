{
  description = "Development environment for llm.c";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = inputs@{ ... }:
    let
      system = "x86_64-linux";
      pkgs = import inputs.nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
      };
      pkgs-unstable = import inputs.nixpkgs-unstable {
        inherit system;
        config = { allowUnfree = true; };
      };
    in {
      devShells.x86_64-linux.default = pkgs.mkShell {
        name = "llm-env";
        nativeBuildInputs = with pkgs; [
          gcc12 # default is v13. gcc versions later than 12 are not supported for cuda.
          gdb
          clang-tools
          valgrind
          cudatoolkit
          cudaPackages.cudnn
          cudaPackages.libcublas
          entr
          python3
        ];

        shellHook = ''
          if [ ! -f ".venv" ]; then
            python -m venv .venv
            source .venv/bin/activate
            pip install -r requirements.txt
          else
            source .venv/bin/activate
          fi

          export USE_CUDNN=0
          # export USE_CUDNN=1 # if you are using turning based gpu (ex: GTX 1660 SUPER). Comment out this line.
          # CUDA environment variables Start
          if [ ! -d "$HOME/cudnn-frontend" ]; then
            git clone https://github.com/NVIDIA/cudnn-frontend.git $HOME/cudnn-frontend
          fi
          export LD_LIBRARY_PATH=${
            pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc pkgs.zlib ]
          }
          export LIBRARY_PATH=/run/opengl-driver/lib:$LIBRARY_PATH # let nvcc find libnvidia-ml.so in compile time
          export LD_LIBRARY_PATH=/run/opengl-driver/lib:$LD_LIBRARY_PATH # let nvcc find libnvidia-ml.so in runtime
          # CUDA environment variables End
          echo "Welcome to llm.c project environment!"
        '';
      };
    };
}

# ref: https://nixos.wiki/wiki/CUDA
