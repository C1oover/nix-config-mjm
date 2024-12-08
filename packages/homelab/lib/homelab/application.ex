defmodule Homelab.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    unless Hush.release_mode?(), do: Hush.resolve!()

    OpentelemetryPhoenix.setup(adapter: :cowboy2)
    OpentelemetryLiveView.setup()
    OpentelemetryEcto.setup([:homelab, :repo])
    OpentelemetryOban.setup()

    children = [
      Homelab.Repo,
      Homelab.Tasks.Repo,
      {Oban, Application.fetch_env!(:homelab, Oban)},
      Homelab.PromEx,
      HomelabWeb.Telemetry,
      Homelab.Cache,
      {Phoenix.PubSub, name: Homelab.PubSub},
      {Finch, name: Homelab.Finch},
      HomelabWeb.Endpoint,
      {Task.Supervisor, name: Homelab.TaskSupervisor}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Homelab.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HomelabWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
