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
      version = "1.0.4";

      src = fetchHex {
        pkg = "castore";
        version = "${version}";
        sha256 = "9418c1b8144e11656f0be99943db4caf04612e3eaecefb5dae9a2a87565584f8";
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
      version = "0.13.0";

      src = fetchHex {
        pkg = "ts_chatterbox";
        version = "${version}";
        sha256 = "b93d19104d86af0b3f2566c4cba2a57d2e06d103728246ba1ac6c3c0ff010aa7";
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

    connection = buildMix rec {
      name = "connection";
      version = "1.1.0";

      src = fetchHex {
        pkg = "connection";
        version = "${version}";
        sha256 = "722c1eb0a418fbe91ba7bd59a47e28008a189d47e37e0e7bb85585a016b2869c";
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
      version = "2.5.0";

      src = fetchHex {
        pkg = "db_connection";
        version = "${version}";
        sha256 = "c92d5ba26cd69ead1ff7582dbb860adeedfff39774105a4f1c92cbb654b55aa2";
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
      version = "3.10.3";

      src = fetchHex {
        pkg = "ecto";
        version = "${version}";
        sha256 = "44bec74e2364d491d70f7e42cd0d690922659d329f6465e89feb8a34e8cd3433";
      };

      beamDeps = [ decimal jason telemetry ];
    };

    ecto_sql = buildMix rec {
      name = "ecto_sql";
      version = "3.10.2";

      src = fetchHex {
        pkg = "ecto_sql";
        version = "${version}";
        sha256 = "68c018debca57cb9235e3889affdaec7a10616a4e3a80c99fa1d01fdafaa9007";
      };

      beamDeps = [ db_connection ecto postgrex telemetry ];
    };

    esbuild = buildMix rec {
      name = "esbuild";
      version = "0.7.1";

      src = fetchHex {
        pkg = "esbuild";
        version = "${version}";
        sha256 = "66661cdf70b1378ee4dc16573fcee67750b59761b2605a0207c267ab9d19f13c";
      };

      beamDeps = [ castore ];
    };

    ex_aws = buildMix rec {
      name = "ex_aws";
      version = "2.5.0";

      src = fetchHex {
        pkg = "ex_aws";
        version = "${version}";
        sha256 = "971b86e5495fc0ae1c318e35e23f389e74cf322f2c02d34037c6fc6d405006f1";
      };

      beamDeps = [ hackney jason mime sweet_xml telemetry ];
    };

    ex_aws_s3 = buildMix rec {
      name = "ex_aws_s3";
      version = "2.5.0";

      src = fetchHex {
        pkg = "ex_aws_s3";
        version = "${version}";
        sha256 = "e6928abe9e04224293c1d7d3eef8df901f0ef4cf6e3125aa1f2b0d2911022ba6";
      };

      beamDeps = [ ex_aws sweet_xml ];
    };

    expo = buildMix rec {
      name = "expo";
      version = "0.4.1";

      src = fetchHex {
        pkg = "expo";
        version = "${version}";
        sha256 = "2ff7ba7a798c8c543c12550fa0e2cbc81b95d4974c65855d8d15ba7b37a1ce47";
      };

      beamDeps = [];
    };

    file_system = buildMix rec {
      name = "file_system";
      version = "0.2.10";

      src = fetchHex {
        pkg = "file_system";
        version = "${version}";
        sha256 = "41195edbfb562a593726eda3b3e8b103a309b733ad25f3d642ba49696bf715dc";
      };

      beamDeps = [];
    };

    finch = buildMix rec {
      name = "finch";
      version = "0.16.0";

      src = fetchHex {
        pkg = "finch";
        version = "${version}";
        sha256 = "f660174c4d519e5fec629016054d60edd822cdfe2b7270836739ac2f97735ec5";
      };

      beamDeps = [ castore mime mint nimble_options nimble_pool telemetry ];
    };

    floki = buildMix rec {
      name = "floki";
      version = "0.34.3";

      src = fetchHex {
        pkg = "floki";
        version = "${version}";
        sha256 = "9577440eea5b97924b4bf3c7ea55f7b8b6dce589f9b28b096cc294a8dc342341";
      };

      beamDeps = [];
    };

    gettext = buildMix rec {
      name = "gettext";
      version = "0.23.1";

      src = fetchHex {
        pkg = "gettext";
        version = "${version}";
        sha256 = "19d744a36b809d810d610b57c27b934425859d158ebd56561bc41f7eeb8795db";
      };

      beamDeps = [ expo ];
    };

    google_protos = buildMix rec {
      name = "google_protos";
      version = "0.3.0";

      src = fetchHex {
        pkg = "google_protos";
        version = "${version}";
        sha256 = "1f6b7fb20371f72f418b98e5e48dae3e022a9a6de1858d4b254ac5a5d0b4035f";
      };

      beamDeps = [ protobuf ];
    };

    gproc = buildRebar3 rec {
      name = "gproc";
      version = "0.8.0";

      src = fetchHex {
        pkg = "gproc";
        version = "${version}";
        sha256 = "580adafa56463b75263ef5a5df4c86af321f68694e7786cb057fd805d1e2a7de";
      };

      beamDeps = [];
    };

    grpcbox = buildRebar3 rec {
      name = "grpcbox";
      version = "0.16.0";

      src = fetchHex {
        pkg = "grpcbox";
        version = "${version}";
        sha256 = "294df743ae20a7e030889f00644001370a4f7ce0121f3bbdaf13cf3169c62913";
      };

      beamDeps = [ acceptor_pool chatterbox ctx gproc ];

      unpackPhase = ''
        runHook preUnpack
        unpackFile "$src"
        chmod -R u+w -- hex-source-grpcbox-0.16.0
        mv hex-source-grpcbox-0.16.0 grpcbox
        sourceRoot=grpcbox
        runHook postUnpack
      '';
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

    heroicons = buildMix rec {
      name = "heroicons";
      version = "0.5.2";

      src = fetchHex {
        pkg = "heroicons";
        version = "${version}";
        sha256 = "7ef96f455c1c136c335f1da0f1d7b12c34002c80a224ad96fc0ebf841a6ffef5";
      };

      beamDeps = [ castore phoenix_live_view ];
    };

    hpack = buildRebar3 rec {
      name = "hpack";
      version = "0.2.3";

      src = fetchHex {
        pkg = "hpack_erl";
        version = "${version}";
        sha256 = "06f580167c4b8b8a6429040df36cc93bba6d571faeaec1b28816523379cbb23a";
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
      version = "0.2.4";

      src = fetchHex {
        pkg = "human_time";
        version = "${version}";
        sha256 = "8447229c17ecb95856fb5811b359cb2ed301447c1f1ab0d43cb063849065c3c8";
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
      version = "1.5.1";

      src = fetchHex {
        pkg = "mint";
        version = "${version}";
        sha256 = "4a63e1e76a7c3956abd2c72f370a0d0aecddc3976dea5c27eccbecfa5e7d5b1e";
      };

      beamDeps = [ castore hpax ];
    };

    nebulex = buildMix rec {
      name = "nebulex";
      version = "2.5.2";

      src = fetchHex {
        pkg = "nebulex";
        version = "${version}";
        sha256 = "61a122302cf42fa61eca22515b1df21aaaa1b98cf462f6dd0998de9797aaf1c7";
      };

      beamDeps = [ telemetry ];
    };

    nimble_options = buildMix rec {
      name = "nimble_options";
      version = "1.0.2";

      src = fetchHex {
        pkg = "nimble_options";
        version = "${version}";
        sha256 = "fd12a8db2021036ce12a309f26f564ec367373265b53e25403f0ee697380f1b8";
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
      version = "2.16.2";

      src = fetchHex {
        pkg = "oban";
        version = "${version}";
        sha256 = "3d343c80948676abf9652da1e793ab6140ba64e9de7c8d6630eb5bb4aa8fea79";
      };

      beamDeps = [ ecto_sql jason postgrex telemetry ];
    };

    octo_fetch = buildMix rec {
      name = "octo_fetch";
      version = "0.3.0";

      src = fetchHex {
        pkg = "octo_fetch";
        version = "${version}";
        sha256 = "c07e44f2214ab153743b7b3182f380798d0b294b1f283811c1e30cff64096d3d";
      };

      beamDeps = [ castore ];
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
      version = "0.2.1";

      src = fetchHex {
        pkg = "opentelemetry_cowboy";
        version = "${version}";
        sha256 = "21ba198dd51294211a498dee720a30d2c2cb4d35ddc843d84f2d4e0a9681be49";
      };

      beamDeps = [ cowboy_telemetry opentelemetry_api opentelemetry_telemetry telemetry ];
    };

    opentelemetry_ecto = buildMix rec {
      name = "opentelemetry_ecto";
      version = "1.1.1";

      src = fetchHex {
        pkg = "opentelemetry_ecto";
        version = "${version}";
        sha256 = "e5f4c76aa9385cefa099a88e19eba90a7a19ef82deec43e0c03c987528bdd826";
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
      version = "1.0.0";

      src = fetchHex {
        pkg = "opentelemetry_oban";
        version = "${version}";
        sha256 = "59ac755f441c8a95d0204f73ef8c168e96a8eaca3abb7bf8adb9b9960a27003f";
      };

      beamDeps = [ oban opentelemetry_api opentelemetry_telemetry telemetry ];
    };

    opentelemetry_phoenix = buildMix rec {
      name = "opentelemetry_phoenix";
      version = "1.1.1";

      src = fetchHex {
        pkg = "opentelemetry_phoenix";
        version = "${version}";
        sha256 = "942850ce28fe21f98d98a743b94163820ce5ba6488333a806dbd1e8161a653d8";
      };

      beamDeps = [ nimble_options opentelemetry_api opentelemetry_process_propagator opentelemetry_semantic_conventions opentelemetry_telemetry plug telemetry ];
    };

    opentelemetry_process_propagator = buildMix rec {
      name = "opentelemetry_process_propagator";
      version = "0.2.2";

      src = fetchHex {
        pkg = "opentelemetry_process_propagator";
        version = "${version}";
        sha256 = "04db13302a34bea8350a13ed9d49c22dfd32c4bc590d8aa88b6b4b7e4f346c61";
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
      version = "1.0.0";

      src = fetchHex {
        pkg = "opentelemetry_telemetry";
        version = "${version}";
        sha256 = "3401d13a1d4b7aa941a77e6b3ec074f0ae77f83b5b2206766ce630123a9291a9";
      };

      beamDeps = [ opentelemetry_api telemetry telemetry_registry ];
    };

    opentelemetry_tesla = buildMix rec {
      name = "opentelemetry_tesla";
      version = "2.2.0";

      src = fetchHex {
        pkg = "opentelemetry_tesla";
        version = "${version}";
        sha256 = "4cad03805923a4ad0d430ba8eafdd0274f880e648d8fdd25931da7e4e25544dd";
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
      version = "1.7.8";

      src = fetchHex {
        pkg = "phoenix";
        version = "${version}";
        sha256 = "7549e3a2f121a232dfbd88ef8dcaeccd671fb09e5fd53ec241a178f248b2c629";
      };

      beamDeps = [ castore jason phoenix_pubsub phoenix_template plug plug_cowboy plug_crypto telemetry websock_adapter ];
    };

    phoenix_ecto = buildMix rec {
      name = "phoenix_ecto";
      version = "4.4.3";

      src = fetchHex {
        pkg = "phoenix_ecto";
        version = "${version}";
        sha256 = "d36c401206f3011fefd63d04e8ef626ec8791975d9d107f9a0817d426f61ac07";
      };

      beamDeps = [ ecto phoenix_html plug ];
    };

    phoenix_html = buildMix rec {
      name = "phoenix_html";
      version = "3.3.3";

      src = fetchHex {
        pkg = "phoenix_html";
        version = "${version}";
        sha256 = "923ebe6fec6e2e3b3e569dfbdc6560de932cd54b000ada0208b5f45024bdd76c";
      };

      beamDeps = [ plug ];
    };

    phoenix_live_dashboard = buildMix rec {
      name = "phoenix_live_dashboard";
      version = "0.8.2";

      src = fetchHex {
        pkg = "phoenix_live_dashboard";
        version = "${version}";
        sha256 = "67a598441b5f583d301a77e0298719f9654887d3d8bf14e80ff0b6acf887ef90";
      };

      beamDeps = [ ecto mime phoenix_live_view telemetry_metrics ];
    };

    phoenix_live_reload = buildMix rec {
      name = "phoenix_live_reload";
      version = "1.4.1";

      src = fetchHex {
        pkg = "phoenix_live_reload";
        version = "${version}";
        sha256 = "9bffb834e7ddf08467fe54ae58b5785507aaba6255568ae22b4d46e2bb3615ab";
      };

      beamDeps = [ file_system phoenix ];
    };

    phoenix_live_view = buildMix rec {
      name = "phoenix_live_view";
      version = "0.20.1";

      src = fetchHex {
        pkg = "phoenix_live_view";
        version = "${version}";
        sha256 = "be494fd1215052729298b0e97d5c2ce8e719c00854b82cd8cf15c1cd7fcf6294";
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
      version = "1.0.3";

      src = fetchHex {
        pkg = "phoenix_template";
        version = "${version}";
        sha256 = "16f4b6588a4152f3cc057b9d0c0ba7e82ee23afa65543da535313ad8d25d8e2c";
      };

      beamDeps = [ phoenix_html ];
    };

    plug = buildMix rec {
      name = "plug";
      version = "1.15.1";

      src = fetchHex {
        pkg = "plug";
        version = "${version}";
        sha256 = "459497bd94d041d98d948054ec6c0b76feacd28eec38b219ca04c0de13c79d30";
      };

      beamDeps = [ mime plug_crypto telemetry ];
    };

    plug_cowboy = buildMix rec {
      name = "plug_cowboy";
      version = "2.6.1";

      src = fetchHex {
        pkg = "plug_cowboy";
        version = "${version}";
        sha256 = "de36e1a21f451a18b790f37765db198075c25875c64834bcc82d90b309eb6613";
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
      version = "0.17.3";

      src = fetchHex {
        pkg = "postgrex";
        version = "${version}";
        sha256 = "946cf46935a4fdca7a81448be76ba3503cff082df42c6ec1ff16a4bdfbfb098d";
      };

      beamDeps = [ db_connection decimal jason ];
    };

    prom_ex = buildMix rec {
      name = "prom_ex";
      version = "1.8.0";

      src = fetchHex {
        pkg = "prom_ex";
        version = "${version}";
        sha256 = "3eea763dfa941e25de50decbf17a6a94dbd2270e7b32f88279aa6e9bbb8e23e7";
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

    sweet_xml = buildMix rec {
      name = "sweet_xml";
      version = "0.7.4";

      src = fetchHex {
        pkg = "sweet_xml";
        version = "${version}";
        sha256 = "e7c4b0bdbf460c928234951def54fe87edf1a170f6896675443279e2dbeba167";
      };

      beamDeps = [];
    };

    swoosh = buildMix rec {
      name = "swoosh";
      version = "1.12.0";

      src = fetchHex {
        pkg = "swoosh";
        version = "${version}";
        sha256 = "87db7ab0f35e358ba5eac3afc7422ed0c8c168a2d219d2a83ad8cb7a424f6cc9";
      };

      beamDeps = [ cowboy ex_aws finch hackney jason mime plug plug_cowboy telemetry ];
    };

    tailwind = buildMix rec {
      name = "tailwind";
      version = "0.2.1";

      src = fetchHex {
        pkg = "tailwind";
        version = "${version}";
        sha256 = "e8a13f6107c95f73e58ed1b4221744e1eb5a093cd1da244432067e19c8c9a277";
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
      version = "0.6.1";

      src = fetchHex {
        pkg = "telemetry_metrics";
        version = "${version}";
        sha256 = "7be9e0871c41732c233be71e4be11b96e56177bf15dde64a8ac9ce72ac9834c6";
      };

      beamDeps = [ telemetry ];
    };

    telemetry_metrics_prometheus_core = buildMix rec {
      name = "telemetry_metrics_prometheus_core";
      version = "1.1.0";

      src = fetchHex {
        pkg = "telemetry_metrics_prometheus_core";
        version = "${version}";
        sha256 = "0dd10e7fe8070095df063798f82709b0a1224c31b8baf6278b423898d591a069";
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

    telemetry_registry = buildMix rec {
      name = "telemetry_registry";
      version = "0.3.1";

      src = fetchHex {
        pkg = "telemetry_registry";
        version = "${version}";
        sha256 = "6d0ca77b691cf854ed074b459a93b87f4c7f5512f8f7743c635ca83da81f939e";
      };

      beamDeps = [ telemetry ];
    };

    tesla = buildMix rec {
      name = "tesla";
      version = "1.7.0";

      src = fetchHex {
        pkg = "tesla";
        version = "${version}";
        sha256 = "2e64f01ebfdb026209b47bc651a0e65203fcff4ae79c11efb73c4852b00dc313";
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
      version = "1.20.0";

      src = fetchHex {
        pkg = "tls_certificate_check";
        version = "${version}";
        sha256 = "ab57b74b1a63dc5775650699a3ec032ec0065005eff1f020818742b7312a8426";
      };

      beamDeps = [ ssl_verify_fun ];
    };

    tz = buildMix rec {
      name = "tz";
      version = "0.26.2";

      src = fetchHex {
        pkg = "tz";
        version = "${version}";
        sha256 = "224b0618dd1e032778a094040bc710ef9aff6e2fa8fffc2716299486f27b9e68";
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
      version = "0.5.4";

      src = fetchHex {
        pkg = "websock_adapter";
        version = "${version}";
        sha256 = "d2c238c79c52cbe223fcdae22ca0bb5007a735b9e933870e241fce66afb4f4ab";
      };

      beamDeps = [ plug plug_cowboy websock ];
    };
  };
in self

