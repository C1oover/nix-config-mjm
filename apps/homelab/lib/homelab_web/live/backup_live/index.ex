defmodule HomelabWeb.BackupLive.Index do
  use HomelabWeb, :live_view

  alias Homelab.Backups.Backup

  def mount(_params, _session, socket) do
    {:ok, stream(socket, :archives, list_archives())}
  end

  defp list_archives() do
    Homelab.Backups.list_archives()
  end

  @borg_repo Application.compile_env!(:homelab, [:borg, :repository])

  def extract_command(%Backup{kind: :borg, name: name}) do
    "borg extract #{@borg_repo}::#{name}"
  end

  @tarsnap_local_keyfile "~/.tarsnap-raspberrypi.key"

  def extract_command(%Backup{kind: :tarsnap, name: name}) do
    "tarsnap --keyfile #{@tarsnap_local_keyfile} -x -f #{name}"
  end

  def extract_command(%Backup{kind: :restic}) do
    ""
  end
end
