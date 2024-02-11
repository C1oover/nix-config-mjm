defmodule HomelabWeb.BackupLive.Show do
  use HomelabWeb, :live_view

  alias Homelab.Backups

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _, socket) do
    [kind, id] = String.split(id, "_", parts: 2)

    {:noreply,
     socket
     |> assign(:archive, Backups.get_archive(String.to_existing_atom(kind), id))}
  end
end
