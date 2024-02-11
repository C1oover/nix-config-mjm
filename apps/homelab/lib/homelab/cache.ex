defmodule Homelab.Cache do
  use Nebulex.Cache,
    otp_app: :homelab,
    adapter: Nebulex.Adapters.Local
end
