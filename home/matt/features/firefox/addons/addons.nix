{ buildFirefoxXpiAddon, fetchurl, lib, stdenv }:
  {
    "linkding-extension" = buildFirefoxXpiAddon {
      pname = "linkding-extension";
      version = "1.6";
      addonId = "{61a05c39-ad45-4086-946f-32adb0a40a9d}";
      url = "https://addons.mozilla.org/firefox/downloads/file/4104891/linkding_extension-1.6.xpi";
      sha256 = "02a1d54e67550bda8ea8be74e5e755c3ee61095a4bc243c00dd1521be7f570ac";
      meta = with lib;
      {
        homepage = "https://github.com/sissbruecker/linkding-extension/";
        description = "Companion extension for the linkding bookmark manager";
        license = licenses.mit;
        platforms = platforms.all;
        };
      };
    "linkding-injector" = buildFirefoxXpiAddon {
      pname = "linkding-injector";
      version = "1.3.0";
      addonId = "{19561335-5a63-4b4e-8182-1eced17f9b47}";
      url = "https://addons.mozilla.org/firefox/downloads/file/4086918/linkding_injector-1.3.0.xpi";
      sha256 = "942d563fc4d766439a83ffc810f997941ced09ba9ce9b9b86f5b3e8cc2c22906";
      meta = with lib;
      {
        homepage = "https://github.com/Fivefold/linkding-injector";
        description = "Injects search results from the linkding bookmark service into search pages like google and duckduckgo";
        license = licenses.mit;
        platforms = platforms.all;
        };
      };
    "minimaltwitter" = buildFirefoxXpiAddon {
      pname = "minimaltwitter";
      version = "5.1.4";
      addonId = "{e7476172-097c-4b77-b56e-f56a894adca9}";
      url = "https://addons.mozilla.org/firefox/downloads/file/4098599/minimaltwitter-5.1.4.xpi";
      sha256 = "b440b41e6e8c351d29388dede774e27c6df536a221f279312380e5f8e187b2c7";
      meta = with lib;
      {
        homepage = "https://typefully.com/minimal-twitter";
        description = "Declutter and refine the Twitter web experience.";
        license = licenses.mit;
        platforms = platforms.all;
        };
      };
    "shinigami-eyes" = buildFirefoxXpiAddon {
      pname = "shinigami-eyes";
      version = "1.0.31";
      addonId = "shinigamieyes@shinigamieyes";
      url = "https://addons.mozilla.org/firefox/downloads/file/4035973/shinigami_eyes-1.0.31.xpi";
      sha256 = "c2ef94a9303040c267202505fd7aff311f6a945b0127be49c55a8b46c8f96db2";
      meta = with lib;
      {
        homepage = "https://shinigami-eyes.github.io/";
        description = "Highlights transphobic/anti-LGBT and trans-friendly subreddits/facebook pages/groups with different colors.\n\nSupports Reddit, Twitter, Facebook, Tumblr, Medium, YouTube, Wikipedia, search engine results and all sites with Disqus comments.";
        license = licenses.mit;
        platforms = platforms.all;
        };
      };
    }