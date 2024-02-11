defmodule Homelab.Backups.Borg do
  @borg_cmd Application.compile_env(:homelab, [:borg, :command], "borg")
  @borg_repo Application.compile_env!(:homelab, [:borg, :repository])

  require OpenTelemetry.Tracer, as: Tracer

  alias __MODULE__.{Archive, ArchiveSummary}

  def list_archives() do
    %{"archives" => archives} = command_json(["list", @borg_repo, "--last", "20"])

    archives
    |> ArchiveSummary.decode()
    |> ArchiveSummary.to_backup()
  end

  def get_archive(name) do
    %{"archives" => [archive]} = command_json(["info", "#{@borg_repo}::#{name}"])

    archive
    |> Archive.decode()
    |> Archive.to_backup()
  end

  @local_timezone Application.compile_env(:homelab, :local_timezone, "Etc/UTC")

  def convert_to_utc(dt) do
    dt
    |> DateTime.from_naive!(@local_timezone)
    |> DateTime.shift_zone!("Etc/UTC")
  end

  defp command_json(args) do
    args = args ++ ["--json"]

    Tracer.with_span :run_borg_command, %{
      attributes: %{"borg.path": @borg_cmd, "borg.args": inspect(args)}
    } do
      {result_str, 0} = System.cmd(@borg_cmd, args)
      Jason.decode!(result_str)
    end
  end
end
