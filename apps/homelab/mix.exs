defmodule Homelab.MixProject do
  use Mix.Project

  def project do
    [
      app: :homelab,
      version: version(),
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: releases()
    ]
  end

  def version do
    case System.get_env("APP_VERSION") do
      nil -> "1.0.0-dev"
      vsn -> vsn
    end
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Homelab.Application, []},
      extra_applications: [:logger, :runtime_tools, :os_mon]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.7.1"},
      {:phoenix_ecto, "~> 4.0"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.19"},
      {:ecto, "~> 3.10"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:esbuild, "~> 0.5", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.1", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.3"},
      # overrides because prom_ex is too specific in its deps
      {:finch, ">= 0.13.0", override: true},
      {:plug_cowboy, "~> 2.6", override: true},
      {:telemetry, "~> 1.2.0", override: true},
      # end overrides
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.2"},
      {:tz, "~> 0.24"},
      {:hush, "~> 1.0"},
      {:tesla, "~> 1.5"},
      {:protobuf, "~> 0.11"},
      {:google_protos, "~> 0.1"},
      {:nebulex, "~> 2.4"},
      {:prom_ex, "~> 1.7"},
      {:oban, "~> 2.14"},
      {:opentelemetry, "~> 1.0"},
      {:opentelemetry_api, "~> 1.0"},
      {:opentelemetry_exporter, "~> 1.0"},
      {:opentelemetry_phoenix, "~> 1.0"},
      {:opentelemetry_cowboy, "~> 0.2"},
      {:opentelemetry_liveview, "1.0.0-rc.4"},
      {:opentelemetry_ecto, "~> 1.0"},
      {:opentelemetry_oban, "~> 1.0"},
      {:opentelemetry_tesla, "~> 2.0"},
      {:timex, "~> 3.7"},
      {:human_time, "~> 0.2.3"},
      {:ex_aws, "~> 2.0"},
      {:ex_aws_s3, "~> 2.0"},
      # only used for AWS (actually MinIO)
      {:hackney, "~> 1.9"},
      {:sweet_xml, "~> 0.6"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "assets.setup", "cmd npm install --prefix assets", "assets.build"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind default", "esbuild default"],
      "assets.deploy": ["tailwind default --minify", "esbuild default --minify", "phx.digest"]
    ]
  end

  defp releases do
    [
      homelab: [
        config_providers: [{Hush.ConfigProvider, nil}],
        include_executables_for: [:unix],
        applications: [
          homelab: :permanent
        ]
      ]
    ]
  end
end
