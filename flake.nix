{
  description = "Dataflare - A simple, easy-to-use database manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # Common libraries needed by Tauri apps
        tauriLibs = with pkgs; [
          webkitgtk_4_1
          gtk3
          cairo
          gdk-pixbuf
          glib
          dbus
          openssl
          librsvg
          libsoup_2_4
          libappindicator-gtk3
          libayatana-appindicator
        ];
        
      in
      {
        packages.default = pkgs.stdenv.mkDerivation rec {
          pname = "dataflare";
          version = "2.1.0";

          src = pkgs.fetchurl {
            url = "https://assets.dataflare.app/release/linux/x86_64/Dataflare-${version}.AppImage";
            hash = "sha256-74g+LAHvLc9BC0TgXkD9sGUweEoCEJk649DimV21DWk=";
          };

          nativeBuildInputs = with pkgs; [
            appimage-run
            makeWrapper
            autoPatchelfHook
          ];

          buildInputs = tauriLibs;

          dontPatchELF = true;
          dontStrip = true;

          unpackPhase = ''
            runHook preUnpack
            
            # Extract using appimage-run with -x flag
            ${pkgs.appimage-run}/bin/appimage-run -x squashfs-root $src
            
            runHook postUnpack
          '';

          installPhase = ''
            runHook preInstall
            
            mkdir -p $out/bin $out/share/applications $out/share/icons/hicolor
            
            # Find the main executable
            main_exe=$(find squashfs-root -name "${pname}" -type f -executable | head -1)
            if [ -z "$main_exe" ]; then
              main_exe="squashfs-root/AppRun"
            fi
            
            # Copy the executable
            cp "$main_exe" $out/bin/${pname}
            
            # Copy resources
            if [ -d "squashfs-root/usr/share" ]; then
              cp -r squashfs-root/usr/share/* $out/share/
            fi
            
            # Handle desktop file
            desktop_file=$(find squashfs-root -name "*.desktop" | head -1)
            if [ -n "$desktop_file" ]; then
              cp "$desktop_file" $out/share/applications/${pname}.desktop
              substituteInPlace $out/share/applications/${pname}.desktop \
                --replace "Exec=AppRun" "Exec=${pname}" \
                --replace "Exec=./" "Exec=${pname}"
            fi
            
            # Handle icons
            for icon in squashfs-root/*.png squashfs-root/*.svg; do
              if [ -f "$icon" ]; then
                # Just install all icons as 128x128
                mkdir -p $out/share/icons/hicolor/128x128/apps
                cp "$icon" $out/share/icons/hicolor/128x128/apps/${pname}.png
              fi
            done
            
            # Create wrapper with proper library path
            wrapProgram $out/bin/${pname} \
              --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath tauriLibs}" \
              --prefix PATH : "${pkgs.lib.makeBinPath [ pkgs.xdg-utils ]}"
            
            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "Dataflare - A simple, easy-to-use database manager";
            homepage = "https://dataflare.app";
            license = licenses.mit;
            platforms = platforms.linux;
            maintainers = [ maintainers.hackr-sh ];
          };
        };

        apps.default = flake-utils.lib.mkApp {
          drv = self.packages.${system}.default;
        };
      });
}