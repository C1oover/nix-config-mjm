defmodule Homelab.Backups.Borg.Archive do
  use Ecto.Schema
  import Ecto.Changeset

  alias Homelab.Backups

  embedded_schema do
    field(:name, :string)
    field(:start, :naive_datetime)
    field(:end, :naive_datetime)
    field(:duration, :float)
    field(:command_line, {:array, :string})
    field(:username, :string)

    embeds_one(:stats, Backups.Borg.Stats)
  end

  def decode(params) when is_list(params) do
    Enum.map(params, &decode/1)
  end

  def decode(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_action!(:decode)
  end

  def to_backup(archives) when is_list(archives) do
    Enum.map(archives, &to_backup/1)
  end

  def to_backup(%__MODULE__{} = archive) do
    start_time = Backups.Borg.convert_to_utc(archive.start)
    end_time = Backups.Borg.convert_to_utc(archive.end)

    %Backups.Backup{
      kind: :borg,
      id: archive.id,
      name: archive.name,
      time: start_time,
      detail: %Backups.Backup.Detail{
        start_time: start_time,
        end_time: end_time,
        duration: archive.duration,
        command_line: archive.command_line,
        username: archive.username,
        stats: Backups.Borg.Stats.to_stats(archive.stats)
      }
    }
  end

  def changeset(data, params) do
    data
    |> cast(params, [:id, :name, :start, :end, :duration, :command_line, :username])
    |> cast_embed(:stats)
  end
end
