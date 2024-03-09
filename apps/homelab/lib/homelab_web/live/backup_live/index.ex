defmodule HomelabWeb.BackupLive.Index do
  use HomelabWeb, :live_view

  alias Homelab.Backups.Backup

  def mount(_params, _session, socket) do
    socket
    |> assign(:onsite_archives, Homelab.Backups.list_archives([:onsite]))
    |> assign_async(:offsite_archives, fn ->
      {:ok, %{offsite_archives: Homelab.Backups.list_archives([:offsite])}}
    end)
    |> then(&{:ok, &1})
  end

  defp all_archives(onsite, offsite) do
    case offsite do
      %{ok?: true, result: offsite} ->
        Homelab.Backups.sort_archives(onsite ++ offsite)

      _ ->
        onsite
    end
  end

  def extract_command(%Backup{} = backup) do
    "sudo restic-#{backup.repository_name} #{backup.location} restore #{backup.id}"
  end
end
