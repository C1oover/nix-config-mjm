{ buildFirefoxXpiAddon, fetchurl, lib, stdenv }:
  {
    "linkding-extension" = buildFirefoxXpiAddon {
      pname = "linkding-extension";
      version = "1.8.0";
      addonId = "{61a05c39-ad45-4086-946f-32adb0a40a9d}";
      url = "https://addons.mozilla.org/firefox/downloads/file/4176160/linkding_extension-1.8.0.xpi";
      sha256 = "1a8bbbaee7b69c1d5b36556dc2690eb7902c907e1cb49bc05cca9f60d8b2c318";
      meta = with lib;
      {
        homepage = "https://github.com/sissbruecker/linkding-extension/";
        description = "Companion extension for the linkding bookmark manager";
        license = licenses.mit;
        mozPermissions = [ "tabs" "http://*/*" "https://*/*" ];
        platforms = platforms.all;
        };
      };
    "linkding-injector" = buildFirefoxXpiAddon {
      pname = "linkding-injector";
      version = "1.3.4";
      addonId = "{19561335-5a63-4b4e-8182-1eced17f9b47}";
      url = "https://addons.mozilla.org/firefox/downloads/file/4190205/linkding_injector-1.3.4.xpi";
      sha256 = "3eb979e0f51eca48f945d82042b0ddd3bb78d438bbae7d3d76edc77ec7ca0e70";
      meta = with lib;
      {
        homepage = "https://github.com/Fivefold/linkding-injector";
        description = "Injects search results from the linkding bookmark service into search pages like google and duckduckgo";
        license = licenses.mit;
        mozPermissions = [
          "https://*/*"
          "http://*/*"
          "storage"
          "*://duckduckgo.com/*"
          "*://search.brave.com/*"
          "*://kagi.com/*"
          "*://www.qwant.com/*"
          "*://*/search?*"
          "*://*/search"
          "*://*.google.com/*"
          "*://*.google.ad/*"
          "*://*.google.ae/*"
          "*://*.google.com.af/*"
          "*://*.google.com.ag/*"
          "*://*.google.com.ai/*"
          "*://*.google.al/*"
          "*://*.google.am/*"
          "*://*.google.co.ao/*"
          "*://*.google.com.ar/*"
          "*://*.google.as/*"
          "*://*.google.at/*"
          "*://*.google.com.au/*"
          "*://*.google.az/*"
          "*://*.google.ba/*"
          "*://*.google.com.bd/*"
          "*://*.google.be/*"
          "*://*.google.bf/*"
          "*://*.google.bg/*"
          "*://*.google.com.bh/*"
          "*://*.google.bi/*"
          "*://*.google.bj/*"
          "*://*.google.com.bn/*"
          "*://*.google.com.bo/*"
          "*://*.google.com.br/*"
          "*://*.google.bs/*"
          "*://*.google.bt/*"
          "*://*.google.co.bw/*"
          "*://*.google.by/*"
          "*://*.google.com.bz/*"
          "*://*.google.ca/*"
          "*://*.google.cd/*"
          "*://*.google.cf/*"
          "*://*.google.cg/*"
          "*://*.google.ch/*"
          "*://*.google.ci/*"
          "*://*.google.co.ck/*"
          "*://*.google.cl/*"
          "*://*.google.cm/*"
          "*://*.google.cn/*"
          "*://*.google.com.co/*"
          "*://*.google.co.cr/*"
          "*://*.google.com.cu/*"
          "*://*.google.cv/*"
          "*://*.google.com.cy/*"
          "*://*.google.cz/*"
          "*://*.google.de/*"
          "*://*.google.dj/*"
          "*://*.google.dk/*"
          "*://*.google.dm/*"
          "*://*.google.com.do/*"
          "*://*.google.dz/*"
          "*://*.google.com.ec/*"
          "*://*.google.ee/*"
          "*://*.google.com.eg/*"
          "*://*.google.es/*"
          "*://*.google.com.et/*"
          "*://*.google.fi/*"
          "*://*.google.com.fj/*"
          "*://*.google.fm/*"
          "*://*.google.fr/*"
          "*://*.google.ga/*"
          "*://*.google.ge/*"
          "*://*.google.gg/*"
          "*://*.google.com.gh/*"
          "*://*.google.com.gi/*"
          "*://*.google.gl/*"
          "*://*.google.gm/*"
          "*://*.google.gr/*"
          "*://*.google.com.gt/*"
          "*://*.google.gy/*"
          "*://*.google.com.hk/*"
          "*://*.google.hn/*"
          "*://*.google.hr/*"
          "*://*.google.ht/*"
          "*://*.google.hu/*"
          "*://*.google.co.id/*"
          "*://*.google.ie/*"
          "*://*.google.co.il/*"
          "*://*.google.im/*"
          "*://*.google.coIn/*"
          "*://*.google.iq/*"
          "*://*.google.is/*"
          "*://*.google.it/*"
          "*://*.google.je/*"
          "*://*.google.com.jm/*"
          "*://*.google.jo/*"
          "*://*.google.co.jp/*"
          "*://*.google.co.ke/*"
          "*://*.google.com.kh/*"
          "*://*.google.ki/*"
          "*://*.google.kg/*"
          "*://*.google.co.kr/*"
          "*://*.google.com.kw/*"
          "*://*.google.kz/*"
          "*://*.google.la/*"
          "*://*.google.com.lb/*"
          "*://*.google.li/*"
          "*://*.google.lk/*"
          "*://*.google.co.ls/*"
          "*://*.google.lt/*"
          "*://*.google.lu/*"
          "*://*.google.lv/*"
          "*://*.google.com.ly/*"
          "*://*.google.co.ma/*"
          "*://*.google.md/*"
          "*://*.google.me/*"
          "*://*.google.mg/*"
          "*://*.google.mk/*"
          "*://*.google.ml/*"
          "*://*.google.com.mm/*"
          "*://*.google.mn/*"
          "*://*.google.ms/*"
          "*://*.google.com.mt/*"
          "*://*.google.mu/*"
          "*://*.google.mv/*"
          "*://*.google.mw/*"
          "*://*.google.com.mx/*"
          "*://*.google.com.my/*"
          "*://*.google.co.mz/*"
          "*://*.google.com.na/*"
          "*://*.google.com.ng/*"
          "*://*.google.com.ni/*"
          "*://*.google.ne/*"
          "*://*.google.nl/*"
          "*://*.google.no/*"
          "*://*.google.com.np/*"
          "*://*.google.nr/*"
          "*://*.google.nu/*"
          "*://*.google.co.nz/*"
          "*://*.google.com.om/*"
          "*://*.google.com.pa/*"
          "*://*.google.com.pe/*"
          "*://*.google.com.pg/*"
          "*://*.google.com.ph/*"
          "*://*.google.com.pk/*"
          "*://*.google.pl/*"
          "*://*.google.pn/*"
          "*://*.google.com.pr/*"
          "*://*.google.ps/*"
          "*://*.google.pt/*"
          "*://*.google.com.py/*"
          "*://*.google.com.qa/*"
          "*://*.google.ro/*"
          "*://*.google.ru/*"
          "*://*.google.rw/*"
          "*://*.google.com.sa/*"
          "*://*.google.com.sb/*"
          "*://*.google.sc/*"
          "*://*.google.se/*"
          "*://*.google.com.sg/*"
          "*://*.google.sh/*"
          "*://*.google.si/*"
          "*://*.google.sk/*"
          "*://*.google.com.sl/*"
          "*://*.google.sn/*"
          "*://*.google.so/*"
          "*://*.google.sm/*"
          "*://*.google.sr/*"
          "*://*.google.st/*"
          "*://*.google.com.sv/*"
          "*://*.google.td/*"
          "*://*.google.tg/*"
          "*://*.google.co.th/*"
          "*://*.google.com.tj/*"
          "*://*.google.tl/*"
          "*://*.google.tm/*"
          "*://*.google.tn/*"
          "*://*.google.to/*"
          "*://*.google.com.tr/*"
          "*://*.google.tt/*"
          "*://*.google.com.tw/*"
          "*://*.google.co.tz/*"
          "*://*.google.com.ua/*"
          "*://*.google.co.ug/*"
          "*://*.google.co.uk/*"
          "*://*.google.com.uy/*"
          "*://*.google.co.uz/*"
          "*://*.google.com.vc/*"
          "*://*.google.co.ve/*"
          "*://*.google.vg/*"
          "*://*.google.co.vi/*"
          "*://*.google.com.vn/*"
          "*://*.google.vu/*"
          "*://*.google.ws/*"
          "*://*.google.rs/*"
          "*://*.google.co.za/*"
          "*://*.google.co.zm/*"
          "*://*.google.co.zw/*"
          "*://*.google.cat/*"
          ];
        platforms = platforms.all;
        };
      };
    "minimaltwitter" = buildFirefoxXpiAddon {
      pname = "minimaltwitter";
      version = "6.0.5";
      addonId = "{e7476172-097c-4b77-b56e-f56a894adca9}";
      url = "https://addons.mozilla.org/firefox/downloads/file/4188531/minimaltwitter-6.0.5.xpi";
      sha256 = "37377039e83c6e8b135784fb87c164479a8a8a45c7edb2bfb1e2ea98e5098f7a";
      meta = with lib;
      {
        homepage = "https://typefully.com/minimal-twitter";
        description = "Declutter and refine the 𝕏 / Twitter web experience.";
        license = licenses.mit;
        mozPermissions = [
          "storage"
          "https://twitter.com/*"
          "https://mobile.twitter.com/*"
          "https://x.com/*"
          ];
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
        mozPermissions = [
          "contextMenus"
          "storage"
          "*://*/*"
          "*://*.facebook.com/*"
          "*://*.youtube.com/*"
          "*://*.reddit.com/*"
          "*://*.twitter.com/*"
          "*://*.medium.com/*"
          "*://disqus.com/*"
          "*://*.tumblr.com/*"
          "*://*.wikipedia.org/*"
          "*://*.rationalwiki.org/*"
          "*://cohost.org/*"
          "*://anarchism.space/*"
          "*://aus.social/*"
          "*://c.im/*"
          "*://chaos.social/*"
          "*://eightpoint.app/*"
          "*://eldritch.cafe/*"
          "*://fosstodon.org/*"
          "*://hachyderm.io/*"
          "*://infosec.exchange/*"
          "*://kolektiva.social/*"
          "*://mas.to/*"
          "*://masto.ai/*"
          "*://mastodon.art/*"
          "*://mastodon.cloud/*"
          "*://mastodon.green/*"
          "*://mastodon.ie/*"
          "*://mastodon.lol/*"
          "*://mastodon.nz/*"
          "*://mastodon.online/*"
          "*://mastodon.scot/*"
          "*://mastodon.social/*"
          "*://mastodon.world/*"
          "*://mastodon.xyz/*"
          "*://mastodonapp.uk/*"
          "*://meow.social/*"
          "*://mstdn.ca/*"
          "*://mstdn.jp/*"
          "*://mstdn.social/*"
          "*://octodon.social/*"
          "*://ohai.social/*"
          "*://pixelfed.social/*"
          "*://queer.party/*"
          "*://sfba.social/*"
          "*://social.transsafety.network/*"
          "*://tech.lgbt/*"
          "*://techhub.social/*"
          "*://toot.cat/*"
          "*://toot.community/*"
          "*://toot.wales/*"
          "*://vulpine.club/*"
          "*://wandering.shop/*"
          "*://duckduckgo.com/*"
          "*://*.bing.com/*"
          "*://*.google.ar/*"
          "*://*.google.at/*"
          "*://*.google.be/*"
          "*://*.google.ca/*"
          "*://*.google.ch/*"
          "*://*.google.co.uk/*"
          "*://*.google.com/*"
          "*://*.google.de/*"
          "*://*.google.dk/*"
          "*://*.google.es/*"
          "*://*.google.fi/*"
          "*://*.google.fr/*"
          "*://*.google.is/*"
          "*://*.google.it/*"
          "*://*.google.no/*"
          "*://*.google.pt/*"
          "*://*.google.se/*"
          ];
        platforms = platforms.all;
        };
      };
    "sixindicator" = buildFirefoxXpiAddon {
      pname = "sixindicator";
      version = "1.3.0";
      addonId = "{8c9cad02-c069-4e93-909d-d874da819c49}";
      url = "https://addons.mozilla.org/firefox/downloads/file/3493442/sixindicator-1.3.0.xpi";
      sha256 = "415ab83ed4ac94d1efe114752a09df29536d1bd54cc9b7e5ce5d9ee55a84226d";
      meta = with lib;
      {
        homepage = "https://github.com/HostedDinner/SixIndicator";
        description = "Shows a simple icon, if IPv6 or IPv4 was used for the request of the site. When clicking on the icon, more information is shown, like the number of requests per domain and if these requests were made via IPv6 or IPv4.";
        license = licenses.mit;
        mozPermissions = [ "tabs" "webRequest" "<all_urls>" ];
        platforms = platforms.all;
        };
      };
    }