{ pkgs ? null
, system ? builtins.currentSystem or "x86_64-linux"
, cudaSupport ? false
, rocmSupport ? false
, vulkanSupport ? false
, mpiSupport ? false
}:

let
  pkgs' = if pkgs != null then pkgs else
    import <nixpkgs> {
      inherit system;
      config = {
        allowUnfree = cudaSupport;
        cudaSupport = cudaSupport;
        rocmSupport = rocmSupport;
      };
    };

  llamaPackages = pkgs'.callPackage ./.devops/nix/scope.nix { };

  llama-cpp = llamaPackages.llama-cpp.override {
    useCuda = cudaSupport;
    useRocm = rocmSupport;
    useVulkan = vulkanSupport;
    useMpi = mpiSupport;
  };
in
pkgs'.mkShell {
  name = "llama.cpp-devshell";

  inputsFrom = [
    llama-cpp
    llamaPackages.python-scripts
  ];

  packages = [
    pkgs'.python3Packages.tiktoken
  ];

  shellHook = ''
    echo "Entering llama.cpp development environment"
    export LD_LIBRARY_PATH="${pkgs'.lib.makeLibraryPath [ pkgs'.stdenv.cc.cc ]}''${LD_LIBRARY_PATH:+:}$LD_LIBRARY_PATH"
  '';
}
