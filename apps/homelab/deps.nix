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

    castore = buildMix rec {
      name = "castore";
      version = "1.0.5";

      src = fetchHex {
        pkg = "castore";
        version = "${version}";
        sha256 = "8d7c597c3e4a64c395980882d4bca3cebb8d74197c590dc272cfd3b6a6310578";
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
      version = "2.10.0";

      src = fetchHex {
        pkg = "cowboy";
        version = "${version}";
        sha256 = "3afdccb7183cc6f143cb14d3cf51fa00e53db9ec80cdcd525482f5e99bc41d6b";
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
      version = "2.12.1";

      src = fetchHex {
        pkg = "cowlib";
        version = "${version}";
        sha256 = "163b73f6367a7341b33c794c4e88e7dbfe6498ac42dcd69ef44c5bc5507c8db0";
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
      version = "3.11.1";

      src = fetchHex {
        pkg = "ecto";
        version = "${version}";
        sha256 = "ebd3d3772cd0dfcd8d772659e41ed527c28b2a8bde4b00fe03e0463da0f1983b";
      };

      beamDeps = [ decimal jason telemetry ];
    };

    ecto_sql = buildMix rec {
      name = "ecto_sql";
      version = "3.11.1";

      src = fetchHex {
        pkg = "ecto_sql";
        version = "${version}";
        sha256 = "ce14063ab3514424276e7e360108ad6c2308f6d88164a076aac8a387e1fea634";
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
      version = "0.36.0";

      src = fetchHex {
        pkg = "floki";
        version = "${version}";
        sha256 = "ab1ca4b1efb0db00df9a8e726524e2c85be88cf65ac092669186e1674d34d74c";
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
      version = "0.1.2";

      src = fetchHex {
        pkg = "hpax";
        version = "${version}";
        sha256 = "2c87843d5a23f5f16748ebe77969880e29809580efdaccd615cd3bed628a8c13";
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
      version = "1.0.2";

      src = fetchHex {
        pkg = "hush";
        version = "${version}";
        sha256 = "6914f73500b50e59bb939edb9d18189a988ed135b6cb6caab5f6bbc9c290b583";
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
      version = "1.2.0";

      src = fetchHex {
        pkg = "mimerl";
        version = "${version}";
        sha256 = "f278585650aa581986264638ebf698f8bb19df297f66ad91b18910dfc6e19323";
      };

      beamDeps = [];
    };

    mint = buildMix rec {
      name = "mint";
      version = "1.5.2";

      src = fetchHex {
        pkg = "mint";
        version = "${version}";
        sha256 = "d77d9e9ce4eb35941907f1d3df38d8f750c357865353e21d335bdcdf6d892a02";
      };

      beamDeps = [ castore hpax ];
    };

    nebulex = buildMix rec {
      name = "nebulex";
      version = "2.6.1";

      src = fetchHex {
        pkg = "nebulex";
        version = "${version}";
        sha256 = "177949fef2dc34a0055d7140b6bc94f6904225e2b5bbed6266ea9679522d23c6";
      };

      beamDeps = [ telemetry ];
    };

    nimble_options = buildMix rec {
      name = "nimble_options";
      version = "1.1.0";

      src = fetchHex {
        pkg = "nimble_options";
        version = "${version}";
        sha256 = "8bbbb3941af3ca9acc7835f5655ea062111c9c27bcac53e004460dfd19008a99";
      };

      beamDeps = [];
    };

    nimble_pool = buildMix rec {
      name = "nimble_pool";
      version = "1.0.0";

      src = fetchHex {
        pkg = "nimble_pool";
        version = "${version}";
        sha256 = "80be3b882d2d351882256087078e1b1952a28bf98d0a287be87e4a24a710b67a";
      };

      beamDeps = [];
    };

    oban = buildMix rec {
      name = "oban";
      version = "2.17.6";

      src = fetchHex {
        pkg = "oban";
        version = "${version}";
        sha256 = "623f3554212e9a776e015156c47f076d66c7b74115ac47a7d3acba0294e65acb";
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
      version = "1.3.1";

      src = fetchHex {
        pkg = "opentelemetry";
        version = "${version}";
        sha256 = "de476b2ac4faad3e3fe3d6e18b35dec9cb338c3b9910c2ce9317836dacad3483";
      };

      beamDeps = [ opentelemetry_api opentelemetry_semantic_conventions ];
    };

    opentelemetry_api = buildMix rec {
      name = "opentelemetry_api";
      version = "1.2.2";

      src = fetchHex {
        pkg = "opentelemetry_api";
        version = "${version}";
        sha256 = "dc77b9a00f137a858e60a852f14007bb66eda1ffbeb6c05d5fe6c9e678b05e9d";
      };

      beamDeps = [ opentelemetry_semantic_conventions ];
    };

    opentelemetry_cowboy = buildRebar3 rec {
      name = "opentelemetry_cowboy";
      version = "0.3.0";

      src = fetchHex {
        pkg = "opentelemetry_cowboy";
        version = "${version}";
        sha256 = "4f44537b4c7430018198d480f55bc88a40f7d0582c3ad927a5bab4ceb39e80ea";
      };

      beamDeps = [ cowboy_telemetry opentelemetry_api opentelemetry_telemetry telemetry ];
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
      version = "1.6.0";

      src = fetchHex {
        pkg = "opentelemetry_exporter";
        version = "${version}";
        sha256 = "1802d1dca297e46f21e5832ecf843c451121e875f73f04db87355a6cb2ba1710";
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
      version = "1.7.11";

      src = fetchHex {
        pkg = "phoenix";
        version = "${version}";
        sha256 = "b1ec57f2e40316b306708fe59b92a16b9f6f4bf50ccfa41aa8c7feb79e0ec02a";
      };

      beamDeps = [ castore jason phoenix_pubsub phoenix_template plug plug_cowboy plug_crypto telemetry websock_adapter ];
    };

    phoenix_ecto = buildMix rec {
      name = "phoenix_ecto";
      version = "4.5.0";

      src = fetchHex {
        pkg = "phoenix_ecto";
        version = "${version}";
        sha256 = "13990570fde09e16959ef214501fe2813e1192d62ca753ec8798980580436f94";
      };

      beamDeps = [ ecto phoenix_html plug ];
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
      version = "1.5.1";

      src = fetchHex {
        pkg = "phoenix_live_reload";
        version = "${version}";
        sha256 = "e8467d308b61f294f68afe12c81bf585584c7ceed40ec8adde88ec176d480a78";
      };

      beamDeps = [ file_system phoenix ];
    };

    phoenix_live_view = buildMix rec {
      name = "phoenix_live_view";
      version = "0.20.12";

      src = fetchHex {
        pkg = "phoenix_live_view";
        version = "${version}";
        sha256 = "ae3a143cc33325f3a4c192b7da1726e6665e154c50e1461af4cd7d561ccfd9ab";
      };

      beamDeps = [ jason phoenix phoenix_html phoenix_template plug telemetry ];
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
      version = "1.15.3";

      src = fetchHex {
        pkg = "plug";
        version = "${version}";
        sha256 = "cc4365a3c010a56af402e0809208873d113e9c38c401cabd88027ef4f5c01fd2";
      };

      beamDeps = [ mime plug_crypto telemetry ];
    };

    plug_cowboy = buildMix rec {
      name = "plug_cowboy";
      version = "2.7.0";

      src = fetchHex {
        pkg = "plug_cowboy";
        version = "${version}";
        sha256 = "d85444fb8aa1f2fc62eabe83bbe387d81510d773886774ebdcb429b3da3c1a4a";
      };

      beamDeps = [ cowboy cowboy_telemetry plug ];
    };

    plug_crypto = buildMix rec {
      name = "plug_crypto";
      version = "2.0.0";

      src = fetchHex {
        pkg = "plug_crypto";
        version = "${version}";
        sha256 = "53695bae57cc4e54566d993eb01074e4d894b65a3766f1c43e2c61a1b0f45ea9";
      };

      beamDeps = [];
    };

    postgrex = buildMix rec {
      name = "postgrex";
      version = "0.17.5";

      src = fetchHex {
        pkg = "postgrex";
        version = "${version}";
        sha256 = "50b8b11afbb2c4095a3ba675b4f055c416d0f3d7de6633a595fc131a828a67eb";
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
      version = "1.15.3";

      src = fetchHex {
        pkg = "swoosh";
        version = "${version}";
        sha256 = "97a667b96ca8cc48a4679f6cd1f40a36d8701cf052587298473614caa70f164a";
      };

      beamDeps = [ cowboy finch hackney jason mime plug plug_cowboy telemetry ];
    };

    tailwind = buildMix rec {
      name = "tailwind";
      version = "0.2.2";

      src = fetchHex {
        pkg = "tailwind";
        version = "${version}";
        sha256 = "ccfb5025179ea307f7f899d1bb3905cd0ac9f687ed77feebc8f67bdca78565c4";
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
      version = "1.2.0";

      src = fetchHex {
        pkg = "telemetry_metrics_prometheus_core";
        version = "${version}";
        sha256 = "9cba950e1c4733468efbe3f821841f34ac05d28e7af7798622f88ecdbbe63ea3";
      };

      beamDeps = [ telemetry telemetry_metrics ];
    };

    telemetry_poller = buildRebar3 rec {
      name = "telemetry_poller";
      version = "1.0.0";

      src = fetchHex {
        pkg = "telemetry_poller";
        version = "${version}";
        sha256 = "b3a24eafd66c3f42da30fc3ca7dda1e9d546c12250a2d60d7b81d264fbec4f6e";
      };

      beamDeps = [ telemetry ];
    };

    tesla = buildMix rec {
      name = "tesla";
      version = "1.8.0";

      src = fetchHex {
        pkg = "tesla";
        version = "${version}";
        sha256 = "10501f360cd926a309501287470372af1a6e1cbed0f43949203a4c13300bc79f";
      };

      beamDeps = [ castore finch hackney jason mime mint telemetry ];
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
      version = "1.21.0";

      src = fetchHex {
        pkg = "tls_certificate_check";
        version = "${version}";
        sha256 = "6cee6cffc35a390840d48d463541d50746a7b0e421acaadb833cfc7961e490e7";
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
      version = "0.5.5";

      src = fetchHex {
        pkg = "websock_adapter";
        version = "${version}";
        sha256 = "4b977ba4a01918acbf77045ff88de7f6972c2a009213c515a445c48f224ffce9";
      };

      beamDeps = [ plug plug_cowboy websock ];
    };
  };
in self

