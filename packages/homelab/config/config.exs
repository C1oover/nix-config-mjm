# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

alias Hush.Provider.{SystemEnvironment, SystemdCreds}

config :homelab,
  ecto_repos: [Homelab.Repo]

config :homelab, Oban,
  repo: Homelab.Repo,
  plugins: [
    {Oban.Plugins.Pruner, max_age: 1800},
    {Oban.Plugins.Cron, crontab: [{"*/5 * * * *", Homelab.Jobs.CreateReminderTasks}]}
  ],
  queues: [default: 10],
  stage_interval: 10_000

config :homelab, Homelab.Cache,
  # When using :shards as backend
  # backend: :shards,
  # GC interval for pushing new generation: 12 hrs
  gc_interval: :timer.hours(12),
  # Max 1 million entries in cache
  max_size: 1_000_000,
  # Max 2 GB of memory
  allocated_memory: 2_000_000_000,
  # GC min timeout: 10 sec
  gc_cleanup_min_timeout: :timer.seconds(10),
  # GC max timeout: 10 min
  gc_cleanup_max_timeout: :timer.minutes(10)

# Configures the endpoint
config :homelab, HomelabWeb.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: HomelabWeb.ErrorHTML, json: HomelabWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Homelab.PubSub,
  live_view: [signing_salt: "THYqdN1s"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :homelab, Homelab.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: System.get_env("MIX_ESBUILD_VERSION"),
  path: System.get_env("MIX_ESBUILD_PATH"),
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: System.get_env("MIX_TAILWIND_VERSION"),
  path: System.get_env("MIX_TAILWIND_PATH"),
  default: [args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ), cd: Path.expand("../assets", __DIR__)]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :tesla, :adapter, {Tesla.Adapter.Finch, name: Homelab.Finch}

config :homelab, :restic,
  onsite: [url: "s3:http://garage.service.consul:3902/restic-backups"],
  offsite: [url: "s3:s3.us-west-001.backblazeb2.com/mjm-restic-backups"]

config :homelab, :gitlab_token, {:hush, SystemdCreds, "homelab_gitlab_token"}

config :homelab, :paperless_token, {:hush, SystemdCreds, "homelab_paperless_token"}

config :homelab, :netbox,
  url: "http://netbox.service.consul:8000/graphql/",
  token: {:hush, SystemdCreds, "homelab_netbox_token"}

config :elixir, :time_zone_database, Tz.TimeZoneDatabase

config :opentelemetry,
  sampler: {:parent_based, %{root: {Homelab.Otel.Sampler, %{}}}},
  span_processor: :batch,
  traces_exporter: :otlp

config :homelab, Homelab.PromEx,
  disabled: false,
  manual_metrics_start_delay: :no_delay,
  drop_metrics_groups: [],
  grafana: :disabled,
  metrics_server: :disabled

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
