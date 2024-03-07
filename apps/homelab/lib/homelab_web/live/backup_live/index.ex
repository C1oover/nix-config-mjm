defmodule HomelabWeb.BackupLive.Index do
  use HomelabWeb, :live_view

  alias Homelab.Backups.Backup

  def mount(_params, _session, socket) do
    {:ok, stream(socket, :archives, list_archives())}
  end

  defp list_archives() do
    Homelab.Backups.list_archives()
  end

  def extract_command(%Backup{} = backup) do
    "sudo restic-#{backup.repository_name} #{backup.location} restore #{backup.id}"
  end
end
