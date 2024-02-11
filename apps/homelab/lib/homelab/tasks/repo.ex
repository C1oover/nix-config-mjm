defmodule Homelab.Tasks.Repo do
  use Ecto.Repo,
    otp_app: :homelab,
    adapter: Homelab.Tasks.Adapter
end
