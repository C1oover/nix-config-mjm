defmodule HomelabWeb.Router do
  use HomelabWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {HomelabWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HomelabWeb do
    pipe_through :browser

    get "/healthz", HealthController, :healthz

    live_session :default, on_mount: [HomelabWeb.Nav] do
      live "/", HomeLive.Index, :index
      live "/backups", BackupLive.Index, :index
      live "/backups/:id", BackupLive.Show, :show
      live "/deploys", DeployLive.Index, :index
      live "/deploys/:id", DeployLive.Show, :show
      live "/tasks", TaskLive.Index, :index
      live "/tasks/:report", TaskLive.Index, :index
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", HomelabWeb do
  #   pipe_through :api
  # end

  import Phoenix.LiveDashboard.Router

  scope "/dev" do
    pipe_through :browser

    live_dashboard "/dashboard", metrics: HomelabWeb.Telemetry

    if Application.compile_env(:homelab, :dev_routes) do
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
