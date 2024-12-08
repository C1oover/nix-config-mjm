{ lib, beamPackages, overrides ? (x: y: {}) }:

let
  buildRebar3 = lib.makeOverridable beamPackages.buildRebar3;
  buildMix = lib.makeOverridable beamPackages.buildMix;
  buildErlangMk = lib.makeOverridable beamPackages.buildErlangMk;

  self = packages // (overrides self packages);

  packages = with beamPackages; with self; {
    acceptor_pool = buildRebar3 rec {
      name = "acceptor_pool";
      version = "1.0.0";

      src = fetchHex {
        pkg = "acceptor_pool";
        version = "${version}";
        sha256 = "0cbcd83fdc8b9ad2eee2067ef8b91a14858a5883cb7cd800e6fcd5803e158788";
      };

      beamDeps = [];
    };

    bandit = buildMix rec {
      name = "bandit";
      version = "1.5.4";

      src = fetchHex {
        pkg = "bandit";
        version = "${version}";
        sha256 = "04c2b38874769af67fe7f10034f606ad6dda1d8f80c4d7a0c616b347584d5aff";
      };

      beamDeps = [ hpax plug telemetry thousand_island websock ];
    };

    castore = buildMix rec {
      name = "castore";
      version = "1.0.7";

      src = fetchHex {
        pkg = "castore";
        version = "${version}";
        sha256 = "da7785a4b0d2a021cd1292a60875a784b6caef71e76bf4917bdee1f390455cf5";
      };

      beamDeps = [];
    };

    certifi = buildRebar3 rec {
      name = "certifi";
      version = "2.12.0";

      src = fetchHex {
        pkg = "certifi";
        version = "${version}";
        sha256 = "ee68d85df22e554040cdb4be100f33873ac6051387baf6a8f6ce82272340ff1c";
      };

      beamDeps = [];
    };

    chatterbox = buildRebar3 rec {
      name = "chatterbox";
      version = "0.15.1";

      src = fetchHex {
        pkg = "ts_chatterbox";
        version = "${version}";
        sha256 = "4f75b91451338bc0da5f52f3480fa6ef6e3a2aeecfc33686d6b3d0a0948f31aa";
      };

      beamDeps = [ hpack ];
    };

    combine = buildMix rec {
      name = "combine";
      version = "0.10.0";

      src = fetchHex {
        pkg = "combine";
        version = "${version}";
        sha256 = "1b1dbc1790073076580d0d1d64e42eae2366583e7aecd455d1215b0d16f2451b";
      };

      beamDeps = [];
    };

    cowboy = buildErlangMk rec {
      name = "cowboy";
      version = "2.12.0";

      src = fetchHex {
        pkg = "cowboy";
        version = "${version}";
        sha256 = "8a7abe6d183372ceb21caa2709bec928ab2b72e18a3911aa1771639bef82651e";
      };

      beamDeps = [ cowlib ranch ];
    };

    cowboy_telemetry = buildRebar3 rec {
      name = "cowboy_telemetry";
      version = "0.4.0";

      src = fetchHex {
        pkg = "cowboy_telemetry";
        version = "${version}";
        sha256 = "7d98bac1ee4565d31b62d59f8823dfd8356a169e7fcbb83831b8a5397404c9de";
      };

      beamDeps = [ cowboy telemetry ];
    };

    cowlib = buildRebar3 rec {
      name = "cowlib";
      version = "2.13.0";

      src = fetchHex {
        pkg = "cowlib";
        version = "${version}";
        sha256 = "e1e1284dc3fc030a64b1ad0d8382ae7e99da46c3246b815318a4b848873800a4";
      };

      beamDeps = [];
    };

    ctx = buildRebar3 rec {
      name = "ctx";
      version = "0.6.0";

      src = fetchHex {
        pkg = "ctx";
        version = "${version}";
        sha256 = "a14ed2d1b67723dbebbe423b28d7615eb0bdcba6ff28f2d1f1b0a7e1d4aa5fc2";
      };

      beamDeps = [];
    };

    db_connection = buildMix rec {
      name = "db_connection";
      version = "2.6.0";

      src = fetchHex {
        pkg = "db_connection";
        version = "${version}";
        sha256 = "c2f992d15725e721ec7fbc1189d4ecdb8afef76648c746a8e1cad35e3b8a35f3";
      };

      beamDeps = [ telemetry ];
    };

    decimal = buildMix rec {
      name = "decimal";
      version = "2.1.1";

      src = fetchHex {
        pkg = "decimal";
        version = "${version}";
        sha256 = "53cfe5f497ed0e7771ae1a475575603d77425099ba5faef9394932b35020ffcc";
      };

      beamDeps = [];
    };

    ecto = buildMix rec {
      name = "ecto";
      version = "3.11.2";

      src = fetchHex {
        pkg = "ecto";
        version = "${version}";
        sha256 = "3c38bca2c6f8d8023f2145326cc8a80100c3ffe4dcbd9842ff867f7fc6156c65";
      };

      beamDeps = [ decimal jason telemetry ];
    };

    ecto_sql = buildMix rec {
      name = "ecto_sql";
      version = "3.11.3";

      src = fetchHex {
        pkg = "ecto_sql";
        version = "${version}";
        sha256 = "e5f36e3d736b99c7fee3e631333b8394ade4bafe9d96d35669fca2d81c2be928";
      };

      beamDeps = [ db_connection ecto postgrex telemetry ];
    };

    esbuild = buildMix rec {
      name = "esbuild";
      version = "0.8.1";

      src = fetchHex {
        pkg = "esbuild";
        version = "${version}";
        sha256 = "25fc876a67c13cb0a776e7b5d7974851556baeda2085296c14ab48555ea7560f";
      };

      beamDeps = [ castore jason ];
    };

    expo = buildMix rec {
      name = "expo";
      version = "0.5.2";

      src = fetchHex {
        pkg = "expo";
        version = "${version}";
        sha256 = "8c9bfa06ca017c9cb4020fabe980bc7fdb1aaec059fd004c2ab3bff03b1c599c";
      };

      beamDeps = [];
    };

    file_system = buildMix rec {
      name = "file_system";
      version = "1.0.0";

      src = fetchHex {
        pkg = "file_system";
        version = "${version}";
        sha256 = "6752092d66aec5a10e662aefeed8ddb9531d79db0bc145bb8c40325ca1d8536d";
      };

      beamDeps = [];
    };

    finch = buildMix rec {
      name = "finch";
      version = "0.18.0";

      src = fetchHex {
        pkg = "finch";
        version = "${version}";
        sha256 = "69f5045b042e531e53edc2574f15e25e735b522c37e2ddb766e15b979e03aa65";
      };

      beamDeps = [ castore mime mint nimble_options nimble_pool telemetry ];
    };

    floki = buildMix rec {
      name = "floki";
      version = "0.36.2";

      src = fetchHex {
        pkg = "floki";
        version = "${version}";
        sha256 = "a8766c0bc92f074e5cb36c4f9961982eda84c5d2b8e979ca67f5c268ec8ed580";
      };

      beamDeps = [];
    };

    gettext = buildMix rec {
      name = "gettext";
      version = "0.24.0";

      src = fetchHex {
        pkg = "gettext";
        version = "${version}";
        sha256 = "bdf75cdfcbe9e4622dd18e034b227d77dd17f0f133853a1c73b97b3d6c770e8b";
      };

      beamDeps = [ expo ];
    };

    google_protos = buildMix rec {
      name = "google_protos";
      version = "0.4.0";

      src = fetchHex {
        pkg = "google_protos";
        version = "${version}";
        sha256 = "4c54983d78761a3643e2198adf0f5d40a5a8b08162f3fc91c50faa257f3fa19f";
      };

      beamDeps = [ protobuf ];
    };

    gproc = buildRebar3 rec {
      name = "gproc";
      version = "0.9.1";

      src = fetchHex {
        pkg = "gproc";
        version = "${version}";
        sha256 = "905088e32e72127ed9466f0bac0d8e65704ca5e73ee5a62cb073c3117916d507";
      };

      beamDeps = [];
    };

    grpcbox = buildRebar3 rec {
      name = "grpcbox";
      version = "0.17.1";

      src = fetchHex {
        pkg = "grpcbox";
        version = "${version}";
        sha256 = "4a3b5d7111daabc569dc9cbd9b202a3237d81c80bf97212fbc676832cb0ceb17";
      };

      beamDeps = [ acceptor_pool chatterbox ctx gproc ];
    };

    hackney = buildRebar3 rec {
      name = "hackney";
      version = "1.20.1";

      src = fetchHex {
        pkg = "hackney";
        version = "${version}";
        sha256 = "fe9094e5f1a2a2c0a7d10918fee36bfec0ec2a979994cff8cfe8058cd9af38e3";
      };

      beamDeps = [ certifi idna metrics mimerl parse_trans ssl_verify_fun unicode_util_compat ];
    };

    hpack = buildRebar3 rec {
      name = "hpack";
      version = "0.3.0";

      src = fetchHex {
        pkg = "hpack_erl";
        version = "${version}";
        sha256 = "d6137d7079169d8c485c6962dfe261af5b9ef60fbc557344511c1e65e3d95fb0";
      };

      beamDeps = [];
    };

    hpax = buildMix rec {
      name = "hpax";
      version = "0.2.0";

      src = fetchHex {
        pkg = "hpax";
        version = "${version}";
        sha256 = "bea06558cdae85bed075e6c036993d43cd54d447f76d8190a8db0dc5893fa2f1";
      };

      beamDeps = [];
    };

    human_time = buildMix rec {
      name = "human_time";
      version = "0.3.1";

      src = fetchHex {
        pkg = "human_time";
        version = "${version}";
        sha256 = "0385ce620d4fa602c2133e64bce474e03138894f81be230581349ef4534d985c";
      };

      beamDeps = [ timex ];
    };

    hush = buildMix rec {
      name = "hush";
      version = "1.1.0";

      src = fetchHex {
        pkg = "hush";
        version = "${version}";
        sha256 = "6207be0280f1688c565ca9947a89c33d40837d35fc39ff7f4045e03dbeec9ec6";
      };

      beamDeps = [];
    };

    idna = buildRebar3 rec {
      name = "idna";
      version = "6.1.1";

      src = fetchHex {
        pkg = "idna";
        version = "${version}";
        sha256 = "92376eb7894412ed19ac475e4a86f7b413c1b9fbb5bd16dccd57934157944cea";
      };

      beamDeps = [ unicode_util_compat ];
    };

    jason = buildMix rec {
      name = "jason";
      version = "1.4.1";

      src = fetchHex {
        pkg = "jason";
        version = "${version}";
        sha256 = "fbb01ecdfd565b56261302f7e1fcc27c4fb8f32d56eab74db621fc154604a7a1";
      };

      beamDeps = [ decimal ];
    };

    metrics = buildRebar3 rec {
      name = "metrics";
      version = "1.0.1";

      src = fetchHex {
        pkg = "metrics";
        version = "${version}";
        sha256 = "69b09adddc4f74a40716ae54d140f93beb0fb8978d8636eaded0c31b6f099f16";
      };

      beamDeps = [];
    };

    mime = buildMix rec {
      name = "mime";
      version = "2.0.5";

      src = fetchHex {
        pkg = "mime";
        version = "${version}";
        sha256 = "da0d64a365c45bc9935cc5c8a7fc5e49a0e0f9932a761c55d6c52b142780a05c";
      };

      beamDeps = [];
    };

    mimerl = buildRebar3 rec {
      name = "mimerl";
      version = "1.3.0";

      src = fetchHex {
        pkg = "mimerl";
        version = "${version}";
        sha256 = "a1e15a50d1887217de95f0b9b0793e32853f7c258a5cd227650889b38839fe9d";
      };

      beamDeps = [];
    };

    mint = buildMix rec {
      name = "mint";
      version = "1.6.1";

      src = fetchHex {
        pkg = "mint";
        version = "${version}";
        sha256 = "4fc518dcc191d02f433393a72a7ba3f6f94b101d094cb6bf532ea54c89423780";
      };

      beamDeps = [ castore hpax ];
    };

    nebulex = buildMix rec {
      name = "nebulex";
      version = "2.6.2";

      src = fetchHex {
        pkg = "nebulex";
        version = "${version}";
        sha256 = "002a1774d5a187eb631ae4006db13df4bb6b325fe2a3c14cb14a1f3e989042b4";
      };

      beamDeps = [ telemetry ];
    };

    nimble_options = buildMix rec {
      name = "nimble_options";
      version = "1.1.1";

      src = fetchHex {
        pkg = "nimble_options";
        version = "${version}";
        sha256 = "821b2470ca9442c4b6984882fe9bb0389371b8ddec4d45a9504f00a66f650b44";
      };

      beamDeps = [];
    };

    nimble_pool = buildMix rec {
      name = "nimble_pool";
      version = "1.1.0";

      src = fetchHex {
        pkg = "nimble_pool";
        version = "${version}";
        sha256 = "af2e4e6b34197db81f7aad230c1118eac993acc0dae6bc83bac0126d4ae0813a";
      };

      beamDeps = [];
    };

    oban = buildMix rec {
      name = "oban";
      version = "2.17.10";

      src = fetchHex {
        pkg = "oban";
        version = "${version}";
        sha256 = "4afd027b8e2bc3c399b54318b4f46ee8c40251fb55a285cb4e38b5363f0ee7c4";
      };

      beamDeps = [ ecto_sql jason postgrex telemetry ];
    };

    octo_fetch = buildMix rec {
      name = "octo_fetch";
      version = "0.4.0";

      src = fetchHex {
        pkg = "octo_fetch";
        version = "${version}";
        sha256 = "cf8be6f40cd519d7000bb4e84adcf661c32e59369ca2827c4e20042eda7a7fc6";
      };

      beamDeps = [ castore ssl_verify_fun ];
    };

    opentelemetry = buildRebar3 rec {
      name = "opentelemetry";
      version = "1.4.0";

      src = fetchHex {
        pkg = "opentelemetry";
        version = "${version}";
        sha256 = "50b32ce127413e5d87b092b4d210a3449ea80cd8224090fe68d73d576a3faa15";
      };

      beamDeps = [ opentelemetry_api opentelemetry_semantic_conventions ];
    };

    opentelemetry_api = buildMix rec {
      name = "opentelemetry_api";
      version = "1.3.0";

      src = fetchHex {
        pkg = "opentelemetry_api";
        version = "${version}";
        sha256 = "b9e5ff775fd064fa098dba3c398490b77649a352b40b0b730a6b7dc0bdd68858";
      };

      beamDeps = [ opentelemetry_semantic_conventions ];
    };

    opentelemetry_ecto = buildMix rec {
      name = "opentelemetry_ecto";
      version = "1.2.0";

      src = fetchHex {
        pkg = "opentelemetry_ecto";
        version = "${version}";
        sha256 = "70dfa2e79932e86f209df00e36c980b17a32f82d175f0068bf7ef9a96cf080cf";
      };

      beamDeps = [ opentelemetry_api opentelemetry_process_propagator telemetry ];
    };

    opentelemetry_exporter = buildRebar3 rec {
      name = "opentelemetry_exporter";
      version = "1.7.0";

      src = fetchHex {
        pkg = "opentelemetry_exporter";
        version = "${version}";
        sha256 = "d0f25f6439ec43f2561537c3fabbe177b38547cddaa3a692cbb8f4770dbefc1e";
      };

      beamDeps = [ grpcbox opentelemetry opentelemetry_api tls_certificate_check ];
    };

    opentelemetry_liveview = buildMix rec {
      name = "opentelemetry_liveview";
      version = "1.0.0-rc.4";

      src = fetchHex {
        pkg = "opentelemetry_liveview";
        version = "${version}";
        sha256 = "e06ab69da7ee46158342cac42f1c22886bdeab53e8d8c4e237c3b3c2cf7b815d";
      };

      beamDeps = [ opentelemetry_api opentelemetry_telemetry telemetry ];
    };

    opentelemetry_oban = buildMix rec {
      name = "opentelemetry_oban";
      version = "1.1.0";

      src = fetchHex {
        pkg = "opentelemetry_oban";
        version = "${version}";
        sha256 = "e2a615568d3b66c9db7562acf3a3a9c35dd1680bec8818dc2980c83869a8a4a4";
      };

      beamDeps = [ oban opentelemetry_api opentelemetry_semantic_conventions opentelemetry_telemetry telemetry ];
    };

    opentelemetry_phoenix = buildMix rec {
      name = "opentelemetry_phoenix";
      version = "1.2.0";

      src = fetchHex {
        pkg = "opentelemetry_phoenix";
        version = "${version}";
        sha256 = "acab991d14ed3efc3f780c5a20cabba27149cf731005b1cc6454c160859debe5";
      };

      beamDeps = [ nimble_options opentelemetry_api opentelemetry_process_propagator opentelemetry_semantic_conventions opentelemetry_telemetry plug telemetry ];
    };

    opentelemetry_process_propagator = buildMix rec {
      name = "opentelemetry_process_propagator";
      version = "0.3.0";

      src = fetchHex {
        pkg = "opentelemetry_process_propagator";
        version = "${version}";
        sha256 = "7243cb6de1523c473cba5b1aefa3f85e1ff8cc75d08f367104c1e11919c8c029";
      };

      beamDeps = [ opentelemetry_api ];
    };

    opentelemetry_semantic_conventions = buildMix rec {
      name = "opentelemetry_semantic_conventions";
      version = "0.2.0";

      src = fetchHex {
        pkg = "opentelemetry_semantic_conventions";
        version = "${version}";
        sha256 = "d61fa1f5639ee8668d74b527e6806e0503efc55a42db7b5f39939d84c07d6895";
      };

      beamDeps = [];
    };

    opentelemetry_telemetry = buildMix rec {
      name = "opentelemetry_telemetry";
      version = "1.1.1";

      src = fetchHex {
        pkg = "opentelemetry_telemetry";
        version = "${version}";
        sha256 = "ee43b14e6866123a3ee1344e3c0d3d7591f4537542c2a925fcdbf46249c9b50b";
      };

      beamDeps = [ opentelemetry_api telemetry ];
    };

    opentelemetry_tesla = buildMix rec {
      name = "opentelemetry_tesla";
      version = "2.4.0";

      src = fetchHex {
        pkg = "opentelemetry_tesla";
        version = "${version}";
        sha256 = "7a0d5f204e1db44615fc197f78de7b614357516e0a91bd78f9f95cddf3bf2be8";
      };

      beamDeps = [ opentelemetry_api opentelemetry_semantic_conventions opentelemetry_telemetry tesla ];
    };

    parse_trans = buildRebar3 rec {
      name = "parse_trans";
      version = "3.4.1";

      src = fetchHex {
        pkg = "parse_trans";
        version = "${version}";
        sha256 = "620a406ce75dada827b82e453c19cf06776be266f5a67cff34e1ef2cbb60e49a";
      };

      beamDeps = [];
    };

    phoenix = buildMix rec {
      name = "phoenix";
      version = "1.7.14";

      src = fetchHex {
        pkg = "phoenix";
        version = "${version}";
        sha256 = "c7859bc56cc5dfef19ecfc240775dae358cbaa530231118a9e014df392ace61a";
      };

      beamDeps = [ castore jason phoenix_pubsub phoenix_template plug plug_cowboy plug_crypto telemetry websock_adapter ];
    };

    phoenix_ecto = buildMix rec {
      name = "phoenix_ecto";
      version = "4.6.1";

      src = fetchHex {
        pkg = "phoenix_ecto";
        version = "${version}";
        sha256 = "0ae544ff99f3c482b0807c5cec2c8289e810ecacabc04959d82c3337f4703391";
      };

      beamDeps = [ ecto phoenix_html plug postgrex ];
    };

    phoenix_html = buildMix rec {
      name = "phoenix_html";
      version = "4.1.1";

      src = fetchHex {
        pkg = "phoenix_html";
        version = "${version}";
        sha256 = "f2f2df5a72bc9a2f510b21497fd7d2b86d932ec0598f0210fed4114adc546c6f";
      };

      beamDeps = [];
    };

    phoenix_live_dashboard = buildMix rec {
      name = "phoenix_live_dashboard";
      version = "0.8.3";

      src = fetchHex {
        pkg = "phoenix_live_dashboard";
        version = "${version}";
        sha256 = "f9470a0a8bae4f56430a23d42f977b5a6205fdba6559d76f932b876bfaec652d";
      };

      beamDeps = [ ecto mime phoenix_live_view telemetry_metrics ];
    };

    phoenix_live_reload = buildMix rec {
      name = "phoenix_live_reload";
      version = "1.5.3";

      src = fetchHex {
        pkg = "phoenix_live_reload";
        version = "${version}";
        sha256 = "b4ec9cd73cb01ff1bd1cac92e045d13e7030330b74164297d1aee3907b54803c";
      };

      beamDeps = [ file_system phoenix ];
    };

    phoenix_live_view = buildMix rec {
      name = "phoenix_live_view";
      version = "0.20.15";

      src = fetchHex {
        pkg = "phoenix_live_view";
        version = "${version}";
        sha256 = "45c48ad1ecc42002e06b4997f964e907a2447576594a72e563f90ee84a9ebe7e";
      };

      beamDeps = [ floki jason phoenix phoenix_html phoenix_template plug telemetry ];
    };

    phoenix_pubsub = buildMix rec {
      name = "phoenix_pubsub";
      version = "2.1.3";

      src = fetchHex {
        pkg = "phoenix_pubsub";
        version = "${version}";
        sha256 = "bba06bc1dcfd8cb086759f0edc94a8ba2bc8896d5331a1e2c2902bf8e36ee502";
      };

      beamDeps = [];
    };

    phoenix_template = buildMix rec {
      name = "phoenix_template";
      version = "1.0.4";

      src = fetchHex {
        pkg = "phoenix_template";
        version = "${version}";
        sha256 = "2c0c81f0e5c6753faf5cca2f229c9709919aba34fab866d3bc05060c9c444206";
      };

      beamDeps = [ phoenix_html ];
    };

    plug = buildMix rec {
      name = "plug";
      version = "1.16.0";

      src = fetchHex {
        pkg = "plug";
        version = "${version}";
        sha256 = "cbf53aa1f5c4d758a7559c0bd6d59e286c2be0c6a1fac8cc3eee2f638243b93e";
      };

      beamDeps = [ mime plug_crypto telemetry ];
    };

    plug_cowboy = buildMix rec {
      name = "plug_cowboy";
      version = "2.7.1";

      src = fetchHex {
        pkg = "plug_cowboy";
        version = "${version}";
        sha256 = "02dbd5f9ab571b864ae39418db7811618506256f6d13b4a45037e5fe78dc5de3";
      };

      beamDeps = [ cowboy cowboy_telemetry plug ];
    };

    plug_crypto = buildMix rec {
      name = "plug_crypto";
      version = "2.1.0";

      src = fetchHex {
        pkg = "plug_crypto";
        version = "${version}";
        sha256 = "131216a4b030b8f8ce0f26038bc4421ae60e4bb95c5cf5395e1421437824c4fa";
      };

      beamDeps = [];
    };

    postgrex = buildMix rec {
      name = "postgrex";
      version = "0.18.0";

      src = fetchHex {
        pkg = "postgrex";
        version = "${version}";
        sha256 = "a042989ba1bc1cca7383ebb9e461398e3f89f868c92ce6671feb7ef132a252d1";
      };

      beamDeps = [ db_connection decimal jason ];
    };

    prom_ex = buildMix rec {
      name = "prom_ex";
      version = "1.9.0";

      src = fetchHex {
        pkg = "prom_ex";
        version = "${version}";
        sha256 = "01f3d4f69ec93068219e686cc65e58a29c42bea5429a8ff4e2121f19db178ee6";
      };

      beamDeps = [ ecto finch jason oban octo_fetch phoenix phoenix_live_view plug plug_cowboy telemetry telemetry_metrics telemetry_metrics_prometheus_core telemetry_poller ];
    };

    protobuf = buildMix rec {
      name = "protobuf";
      version = "0.12.0";

      src = fetchHex {
        pkg = "protobuf";
        version = "${version}";
        sha256 = "75fa6cbf262062073dd51be44dd0ab940500e18386a6c4e87d5819a58964dc45";
      };

      beamDeps = [ jason ];
    };

    ranch = buildRebar3 rec {
      name = "ranch";
      version = "1.8.0";

      src = fetchHex {
        pkg = "ranch";
        version = "${version}";
        sha256 = "49fbcfd3682fab1f5d109351b61257676da1a2fdbe295904176d5e521a2ddfe5";
      };

      beamDeps = [];
    };

    ssl_verify_fun = buildRebar3 rec {
      name = "ssl_verify_fun";
      version = "1.1.7";

      src = fetchHex {
        pkg = "ssl_verify_fun";
        version = "${version}";
        sha256 = "fe4c190e8f37401d30167c8c405eda19469f34577987c76dde613e838bbc67f8";
      };

      beamDeps = [];
    };

    swoosh = buildMix rec {
      name = "swoosh";
      version = "1.16.9";

      src = fetchHex {
        pkg = "swoosh";
        version = "${version}";
        sha256 = "878b1a7a6c10ebbf725a3349363f48f79c5e3d792eb621643b0d276a38acc0a6";
      };

      beamDeps = [ bandit cowboy finch hackney jason mime plug plug_cowboy telemetry ];
    };

    tailwind = buildMix rec {
      name = "tailwind";
      version = "0.2.3";

      src = fetchHex {
        pkg = "tailwind";
        version = "${version}";
        sha256 = "8e45e7a34a676a7747d04f7913a96c770c85e6be810a1d7f91e713d3a3655b5d";
      };

      beamDeps = [ castore ];
    };

    telemetry = buildRebar3 rec {
      name = "telemetry";
      version = "1.2.1";

      src = fetchHex {
        pkg = "telemetry";
        version = "${version}";
        sha256 = "dad9ce9d8effc621708f99eac538ef1cbe05d6a874dd741de2e689c47feafed5";
      };

      beamDeps = [];
    };

    telemetry_metrics = buildMix rec {
      name = "telemetry_metrics";
      version = "0.6.2";

      src = fetchHex {
        pkg = "telemetry_metrics";
        version = "${version}";
        sha256 = "9b43db0dc33863930b9ef9d27137e78974756f5f198cae18409970ed6fa5b561";
      };

      beamDeps = [ telemetry ];
    };

    telemetry_metrics_prometheus_core = buildMix rec {
      name = "telemetry_metrics_prometheus_core";
      version = "1.2.1";

      src = fetchHex {
        pkg = "telemetry_metrics_prometheus_core";
        version = "${version}";
        sha256 = "5e2c599da4983c4f88a33e9571f1458bf98b0cf6ba930f1dc3a6e8cf45d5afb6";
      };

      beamDeps = [ telemetry telemetry_metrics ];
    };

    telemetry_poller = buildRebar3 rec {
      name = "telemetry_poller";
      version = "1.1.0";

      src = fetchHex {
        pkg = "telemetry_poller";
        version = "${version}";
        sha256 = "9eb9d9cbfd81cbd7cdd24682f8711b6e2b691289a0de6826e58452f28c103c8f";
      };

      beamDeps = [ telemetry ];
    };

    tesla = buildMix rec {
      name = "tesla";
      version = "1.10.0";

      src = fetchHex {
        pkg = "tesla";
        version = "${version}";
        sha256 = "eb1cab91a367667ba7391d3d2c7c46c0ac016a80718b32fb179b54880962e0a8";
      };

      beamDeps = [ castore finch hackney jason mime mint telemetry ];
    };

    thousand_island = buildMix rec {
      name = "thousand_island";
      version = "1.3.5";

      src = fetchHex {
        pkg = "thousand_island";
        version = "${version}";
        sha256 = "2be6954916fdfe4756af3239fb6b6d75d0b8063b5df03ba76fd8a4c87849e180";
      };

      beamDeps = [ telemetry ];
    };

    timex = buildMix rec {
      name = "timex";
      version = "3.7.11";

      src = fetchHex {
        pkg = "timex";
        version = "${version}";
        sha256 = "8b9024f7efbabaf9bd7aa04f65cf8dcd7c9818ca5737677c7b76acbc6a94d1aa";
      };

      beamDeps = [ combine gettext tzdata ];
    };

    tls_certificate_check = buildRebar3 rec {
      name = "tls_certificate_check";
      version = "1.22.1";

      src = fetchHex {
        pkg = "tls_certificate_check";
        version = "${version}";
        sha256 = "3092be0babdc0e14c2e900542351e066c0fa5a9cf4b3597559ad1e67f07938c0";
      };

      beamDeps = [ ssl_verify_fun ];
    };

    tz = buildMix rec {
      name = "tz";
      version = "0.26.5";

      src = fetchHex {
        pkg = "tz";
        version = "${version}";
        sha256 = "c4f9392d710582c7108b6b8c635f4981120ec4b2072adbd242290fc842338183";
      };

      beamDeps = [ castore mint ];
    };

    tzdata = buildMix rec {
      name = "tzdata";
      version = "1.1.1";

      src = fetchHex {
        pkg = "tzdata";
        version = "${version}";
        sha256 = "a69cec8352eafcd2e198dea28a34113b60fdc6cb57eb5ad65c10292a6ba89787";
      };

      beamDeps = [ hackney ];
    };

    unicode_util_compat = buildRebar3 rec {
      name = "unicode_util_compat";
      version = "0.7.0";

      src = fetchHex {
        pkg = "unicode_util_compat";
        version = "${version}";
        sha256 = "25eee6d67df61960cf6a794239566599b09e17e668d3700247bc498638152521";
      };

      beamDeps = [];
    };

    websock = buildMix rec {
      name = "websock";
      version = "0.5.3";

      src = fetchHex {
        pkg = "websock";
        version = "${version}";
        sha256 = "6105453d7fac22c712ad66fab1d45abdf049868f253cf719b625151460b8b453";
      };

      beamDeps = [];
    };

    websock_adapter = buildMix rec {
      name = "websock_adapter";
      version = "0.5.6";

      src = fetchHex {
        pkg = "websock_adapter";
        version = "${version}";
        sha256 = "e04378d26b0af627817ae84c92083b7e97aca3121196679b73c73b99d0d133ea";
      };

      beamDeps = [ bandit plug plug_cowboy websock ];
    };
  };
in self

