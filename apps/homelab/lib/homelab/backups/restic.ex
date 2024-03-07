defmodule Homelab.Backups.Restic do
  @repositories [
    "home-assistant",
    "mediaserver",
    "paperless",
    "postgresql",
    "vaultwarden"
  ]

  require OpenTelemetry.Tracer, as: Tracer

  alias __MODULE__.Snapshot

  def list_snapshots() do
    Enum.flat_map([:onsite, :offsite], &list_snapshots/1)
  end

  def list_snapshots(location) do
    Enum.flat_map(@repositories, &list_snapshots(location, &1))
  end

  def list_snapshots(location, repository) do
    repo = repository_url(location, repository)
    env = location_env(location)
    snapshots = command_json(["-r", repo, "snapshots"], env)

    snapshots
    |> Snapshot.decode()
    |> Snapshot.to_backup(location, repository)
  end

  defp command_json(args, env) do
    args = ["--json" | args]

    Tracer.with_span :run_restic_command, %{
      attributes: %{"restic.args": inspect(args)}
    } do
      {result_str, 0} = System.cmd("restic", args, env: env)
      # TODO set attribute for response length
      Jason.decode!(result_str)
    end
  end

  defp repository_url(location, repository) do
    location
    |> location_cfg()
    |> Keyword.fetch!(:url)
    |> Kernel.<>("/#{repository}")
  end

  defp location_env(location) do
    cfg = location_cfg(location)
    key_id = File.read!(cfg[:key_id_file])
    secret_key = File.read!(cfg[:secret_key_file])

    [
      {"AWS_ACCESS_KEY_ID", key_id},
      {"AWS_SECRET_ACCESS_KEY", secret_key}
    ]
  end

  defp location_cfg(location) do
    Keyword.fetch!(restic_cfg(), location)
  end

  defp restic_cfg() do
    Application.fetch_env!(:homelab, :restic)
  end
end
