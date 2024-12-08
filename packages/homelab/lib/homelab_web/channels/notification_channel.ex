defmodule HomelabWeb.NotificationChannel do
  use HomelabWeb, :channel

  @impl true
  def join("notifications", _payload, socket) do
    {:ok, socket}
  end
end
