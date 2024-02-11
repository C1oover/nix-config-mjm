defmodule Homelab.Backups.Tarsnap do
  @tarsnap_cmd Application.compile_env(:homelab, [:tarsnap, :command], "tarsnap")
  @tarsnap_key Application.compile_env(:homelab, [:tarsnap, :keyfile], "/dev/null")
  @local_timezone Application.compile_env(:homelab, :local_timezone, "Etc/UTC")

  require OpenTelemetry.Tracer, as: Tracer

  alias Homelab.Backups.Backup

  def list_archives() do
    run_command(["--keyfile", @tarsnap_key, "--list-archives", "-v"])
    |> String.split("\n", trim: true)
    |> Enum.map(fn archive_line ->
      [name, time_str] = String.split(archive_line, "\t")

      time =
        time_str
        |> NaiveDateTime.from_iso8601!()
        |> DateTime.from_naive!(@local_timezone)
        |> DateTime.shift_zone!("Etc/UTC")

      %Backup{
        kind: :tarsnap,
        id: name,
        name: name,
        time: time
      }
    end)
  end

  defp run_command(args) do
    Tracer.with_span :run_tarsnap_command, %{
      attributes: %{"tarsnap.path": @tarsnap_cmd, "tarsnap.args": inspect(args)}
    } do
      {result_str, 0} = System.cmd(@tarsnap_cmd, args)
      result_str
    end
  end
end
