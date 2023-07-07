{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";

    sanitizers-cmake = {
      url = "github:luis-hebendanz/sanitizers-cmake";
      flake = false;
    };

    clang-format-cmake = {
      url = "github:luis-hebendanz/clangformat-cmake";
      flake = false;
    };

    luispkgs.url = "github:Luis-Hebendanz/nixpkgs/fix_ns3";
  };

  outputs = { self, nixpkgs, utils, clang-format-cmake, sanitizers-cmake, luispkgs }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import luispkgs {
          inherit system; config = {
          allowUnfree = true;
        };
        };

        my-python-packages = ps: with ps; [
          # Add python dependencies here
          autopep8
          setuptools
          ipython
          pkgs.ns-3
        ];
        python-with-my-packages = pkgs.python3.withPackages my-python-packages;

        # luis = import luispkgs
        # {
        #   system = "x86_64-linux";
        #   config = {
        #     allowUnfree = true;
        #   };
        # };

        # buildInputs
        buildDeps = with pkgs; [
          pkg-config
          cmake
          llvmPackages_latest.clang
          llvmPackages_latest.lld
          ns-3
        ];

        # nativeBuildInputs
        runtimeDeps = with pkgs; [
          shellcheck
          llvmPackages_latest.bintools
          python-with-my-packages
        ];

        myCBuild = pkgs.llvmPackages_latest.stdenv.mkDerivation rec {
          name = "network-simulator";
          src = "${self}";

          cmakeFlags = [
            "-DCMAKE_SANITIZER_MOD=${sanitizers-cmake}"
            "-DCMAKE_FORMAT_MOD=${clang-format-cmake}"
            "-DCMAKE_BUILD_TYPE=Debug"
          ];
          hardeningDisable = [ "all" ];

          dontStrip = true;

          postFixup = ''
            patchelf --set-rpath "${pkgs.lib.makeLibraryPath [ pkgs.gcc-unwrapped.lib ]}:$(patchelf --print-rpath $out/bin/${name})" $out/bin/${name}
          '';
          nativeBuildInputs = buildDeps;
          buildInputs = runtimeDeps;
        };
      in
      rec {
        packages = {
          default = myCBuild;
        };

        devShell = pkgs.mkShellNoCC {
          nativeBuildInputs = runtimeDeps ++ buildDeps;
          buildInputs = runtimeDeps ++ buildDeps;
          shellHook = ''
            export hardeningDisable=all
            export NS3_LOC=${pkgs.ns-3}
            export GLIBC=${pkgs.glibc}
            export CMAKE_SANITIZER_MOD=${sanitizers-cmake}
            export CMAKE_FORMAT_MOD=${clang-format-cmake}

            export ASAN_OPTIONS=check_initialization_order=1
            ln -sf build/compile_commands.json compile_commands.json
          '';
        };
      });
}
