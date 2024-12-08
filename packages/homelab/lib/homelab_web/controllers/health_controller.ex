defmodule HomelabWeb.HealthController do
  use HomelabWeb, :controller

  def healthz(conn, _params) do
    text(conn, "OK")
  end
end
