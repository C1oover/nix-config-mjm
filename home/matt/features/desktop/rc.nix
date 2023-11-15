{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.plasma-manager.homeManagerModules.plasma-manager
  ];

  programs.plasma = {
    enable = true;
    shortcuts = {
      "controku.desktop"._launch = "Meta+Shift+C";
      "kitty.desktop"._launch = "Meta+Return";
      "night-mode.desktop"._launch = "Meta+Shift+N";

      kded5.display = ["Display" "Meta+P"];

      kwin = {
        "Edit Tiles" = "Meta+T";
        "Expose" = "Ctrl+F9";
        "ExposeAll" = ["Ctrl+F10" "Launch (C)"];
        "ExposeClass" = "Ctrl+F7";
        "Kill Window" = "Meta+Ctrl+Esc";
        "MoveMouseToCenter" = "Meta+F6";
        "MoveMouseToFocus" = "Meta+F5";
        "Overview" = "Meta+W";
        "Show Desktop" = "Meta+D";
        "ShowDesktopGrid" = "Meta+F8";
        "Suspend Compositing" = "Alt+Shift+F12";
        "Switch One Desktop Down" = "Meta+Ctrl+Down";
        "Switch One Desktop Up" = "Meta+Ctrl+Up";
        "Switch One Desktop to the Left" = "Meta+Ctrl+Left";
        "Switch One Desktop to the Right" = "Meta+Ctrl+Right";
        "Switch Window Down" = "Meta+Down";
        "Switch Window Left" = "Meta+Left";
        "Switch Window Right" = "Meta+Right";
        "Switch Window Up" = "Meta+Up";
        "Switch to Desktop 1" = ["Ctrl+F1" "Meta+1"];
        "Switch to Desktop 2" = ["Ctrl+F2" "Meta+2"];
        "Switch to Desktop 3" = ["Ctrl+F3" "Meta+3"];
        "Switch to Desktop 4" = ["Ctrl+F4" "Meta+4"];
        "Walk Through Windows" = "Meta+Tab";
        "Walk Through Windows (Reverse)" = "Meta+Shift+Tab";
        "Window Close" = ["Meta+Q" "Alt+F4"];
        "Window Fullscreen" = "Meta+F";
        "Window Maximize" = "Meta+PgUp";
        "Window Minimize" = "Meta+PgDown";
        "Window One Desktop Down" = "Meta+Ctrl+Shift+Down";
        "Window One Desktop Up" = "Meta+Ctrl+Shift+Up";
        "Window One Desktop to the Left" = "Meta+Ctrl+Shift+Left";
        "Window One Desktop to the Right" = "Meta+Ctrl+Shift+Right";
        "Window Operations Menu" = "Alt+F3";
        "Window Quick Tile Bottom" = [];
        "Window Quick Tile Bottom Left" = [];
        "Window Quick Tile Bottom Right" = [];
        "Window Quick Tile Left" = [];
        "Window Quick Tile Right" = [];
        "Window Quick Tile Top" = [];
        "Window Quick Tile Top Left" = [];
        "Window Quick Tile Top Right" = [];
        "Window to Desktop 1" = "Meta+!";
        "Window to Desktop 2" = "Meta+@";
        "Window to Desktop 3" = "Meta+#";
        "Window to Desktop 4" = "Meta+$";
        "Window to Next Screen" = "Meta+Shift+Right";
        "Window to Previous Screen" = "Meta+Shift+Left";
        "view_actual_size" = "Meta+0";
        "view_zoom_in" = ["Meta++" "Meta+="];
        "view_zoom_out" = "Meta+-";
      };

      "org.kde.dolphin.desktop"._launch = "Meta+E";

      "org.kde.krunner.desktop".RunClipboard = "Alt+Shift+F2";
      "org.kde.krunner.desktop"._launch = ["Search" "Meta+Space" "Alt+F2"];

      "org.kde.plasma.emojier.desktop"._launch = ["Meta+." "Meta+Ctrl+Alt+Shift+Space"];

      "org.kde.spectacle.desktop" = {
        ActiveWindowScreenShot = "Meta+Print";
        CurrentMonitorScreenShot = [];
        FullScreenScreenShot = "Shift+Print";
        OpenWithoutScreenshot = [];
        RectangularRegionScreenShot = "Meta+Shift+Print";
        WindowUnderCursorScreenShot = "Meta+Ctrl+Print";
        _launch = "Print";
      };

      plasmashell = {
        "activate task manager entry 1" = [];
        "activate task manager entry 10" = [];
        "activate task manager entry 2" = [];
        "activate task manager entry 3" = [];
        "activate task manager entry 4" = [];
        "activate task manager entry 5" = [];
        "activate task manager entry 6" = [];
        "activate task manager entry 7" = [];
        "activate task manager entry 8" = [];
        "activate task manager entry 9" = [];
        "clear-history" = [];
        "clipboard_action" = "Meta+Ctrl+X";
        "cycle-panels" = "Meta+Alt+P";
        "cycleNextAction" = [];
        "cyclePrevAction" = [];
        "edit_clipboard" = [];
        "manage activities" = [];
        "next activity" = [];
        "previous activity" = [];
        "repeat_action" = "Meta+Ctrl+R";
        "show dashboard" = "Ctrl+F12";
        "show-on-mouse-pos" = "Meta+V";
        "stop current activity" = "Meta+S";
        "switch to next activity" = [];
        "switch to previous activity" = [];
      };
    };
    configFile = {
      # "kcminputrc"."Libinput.1133.49738.Logitech Gaming Mouse G600"."PointerAcceleration" = "-0.200";
      "kcminputrc"."Libinput.2362.628.PIXA3854:00 093A:0274 Touchpad"."ClickMethod" = 2;
      "kcminputrc"."Libinput.2362.628.PIXA3854:00 093A:0274 Touchpad"."NaturalScroll" = true;
      "kcminputrc"."Mouse"."X11LibInputXAccelProfileFlat" = true;

      "kded5rc"."Module-browserintegrationreminder"."autoload" = false;
      "kded5rc"."Module-device_automounter"."autoload" = false;

      "kdeglobals"."General"."BrowserApplication" = "firefox.desktop";
      "kdeglobals"."General"."TerminalApplication" = "kitty";
      "kdeglobals"."General"."TerminalService" = "kitty.desktop";
      "kdeglobals"."General"."XftHintStyle" = "hintslight";
      "kdeglobals"."General"."XftSubPixel" = "none";
      "kdeglobals"."KDE"."AnimationDurationFactor" = 0.35355339059327373;
      "kdeglobals"."KDE"."widgetStyle" = "Breeze";
      "kdeglobals"."KFileDialog Settings"."Allow Expansion" = false;
      "kdeglobals"."KFileDialog Settings"."Automatically select filename extension" = true;
      "kdeglobals"."KFileDialog Settings"."Breadcrumb Navigation" = true;
      "kdeglobals"."KFileDialog Settings"."Decoration position" = 2;
      "kdeglobals"."KFileDialog Settings"."LocationCombo Completionmode" = 5;
      "kdeglobals"."KFileDialog Settings"."PathCombo Completionmode" = 5;
      "kdeglobals"."KFileDialog Settings"."Show Bookmarks" = false;
      "kdeglobals"."KFileDialog Settings"."Show Full Path" = false;
      "kdeglobals"."KFileDialog Settings"."Show Inline Previews" = true;
      "kdeglobals"."KFileDialog Settings"."Show Preview" = false;
      "kdeglobals"."KFileDialog Settings"."Show Speedbar" = true;
      "kdeglobals"."KFileDialog Settings"."Show hidden files" = false;
      "kdeglobals"."KFileDialog Settings"."Sort by" = "Name";
      "kdeglobals"."KFileDialog Settings"."Sort directories first" = true;
      "kdeglobals"."KFileDialog Settings"."Sort hidden files last" = false;
      "kdeglobals"."KFileDialog Settings"."Sort reversed" = false;
      "kdeglobals"."KFileDialog Settings"."Speedbar Width" = 152;
      "kdeglobals"."KFileDialog Settings"."View Style" = "DetailTree";
      "kdeglobals"."WM"."activeBackground" = "227,229,231";
      "kdeglobals"."WM"."activeBlend" = "227,229,231";
      "kdeglobals"."WM"."activeForeground" = "35,38,41";
      "kdeglobals"."WM"."inactiveBackground" = "239,240,241";
      "kdeglobals"."WM"."inactiveBlend" = "239,240,241";
      "kdeglobals"."WM"."inactiveForeground" = "112,125,138";

      "kglobalshortcutsrc"."controku.desktop"."_k_friendly_name" = "controku";
      "kglobalshortcutsrc"."kitty.desktop"."_k_friendly_name" = "kitty";
      "kglobalshortcutsrc"."night-mode.desktop"."_k_friendly_name" = "night-mode";

      "klipperrc"."General"."IgnoreImages" = false;
      "klipperrc"."General"."MaxClipItems" = 1000;

      "krunnerrc"."General"."FreeFloating" = true;

      "kscreenlockerrc"."Greeter.Wallpaper.org.kde.image.General"."Image" = "${pkgs.plasma5Packages.plasma-workspace-wallpapers}/share/wallpapers/Shell/";
      "kscreenlockerrc"."Greeter.Wallpaper.org.kde.image.General"."PreviewImage" = "${pkgs.plasma5Packages.plasma-workspace-wallpapers}/share/wallpapers/Shell/";

      "kwinrc"."Desktops"."Id_1" = "a61b19cd-ecd0-46bd-9fd8-f262ee95117b";
      "kwinrc"."Desktops"."Id_2" = "bdcd8814-0752-44b0-9312-e69128fd52f1";
      "kwinrc"."Desktops"."Id_3" = "9ab21903-b830-4114-8774-ca2819c72256";
      "kwinrc"."Desktops"."Number" = 3;
      "kwinrc"."Desktops"."Rows" = 1;
      "kwinrc"."Effect-kwin4_effect_translucency"."Inactive" = 96;
      "kwinrc"."Effect-zoom"."ZoomFactor" = 1.2;
      "kwinrc"."Plugins"."kwin4_effect_squashEnabled" = false;
      "kwinrc"."Plugins"."kwin4_effect_translucencyEnabled" = true;
      "kwinrc"."Plugins"."magiclampEnabled" = true;
      "kwinrc"."Plugins"."wobblywindowsEnabled" = true;
      "kwinrc"."Tiling"."padding" = 4;
      "kwinrc"."Tiling.213a9620-187e-58a6-b80b-85d8fb95dfce"."tiles" = "{\"layoutDirection\":\"horizontal\",\"tiles\":[{\"width\":0.25},{\"width\":0.5},{\"width\":0.25}]}";
      "kwinrc"."Tiling.3c373409-48e0-57e9-a1a9-eb32e49f8772"."tiles" = "{\"layoutDirection\":\"horizontal\",\"tiles\":[{\"width\":0.5},{\"width\":0.5}]}";
      "kwinrc"."Tiling.489782c3-84bf-5a4b-8a36-195b829ccfcc"."tiles" = "{\"layoutDirection\":\"horizontal\",\"tiles\":[{\"width\":0.5},{\"width\":0.5}]}";
      "kwinrc"."Tiling.5cf27aae-2740-593b-8903-f10c20b1b1b8"."tiles" = "{\"layoutDirection\":\"vertical\",\"tiles\":[{\"height\":0.33},{\"height\":0.34},{\"height\":0.33}]}";
      "kwinrc"."Windows"."FocusPolicy" = "FocusFollowsMouse";
      "kwinrc"."Windows"."NextFocusPrefersMouse" = true;
      "kwinrc"."Windows"."RollOverDesktops" = true;
      "kwinrc"."Xwayland"."Scale" = 1.5;

      "kxkbrc"."Layout"."Options" = "caps:ctrl_modifier";
      "kxkbrc"."Layout"."ResetOldOptions" = true;

      "plasma-localerc"."Formats"."LANG" = "en_US.UTF-8";
    };
  };
}
