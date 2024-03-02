defmodule Homelab.Backups.Backup do
  use Ecto.Schema

  embedded_schema do
    field(:kind, Ecto.Enum, values: [:borg, :restic, :tarsnap])
    field(:name, :string)
    field(:time, :utc_datetime)
    field(:location, Ecto.Enum, values: [:onsite, :offsite])
    field(:repository_name, :string)

    embeds_one(:detail, Detail, primary_key: false) do
      field(:start_time, :utc_datetime)
      field(:end_time, :utc_datetime)
      field(:duration, :float)
      field(:command_line, {:array, :string})
      field(:username, :string)

      embeds_one(:stats, Stats, primary_key: false) do
        field(:compressed_size, :integer)
        field(:deduplicated_size, :integer)
        field(:original_size, :integer)
        field(:num_files, :integer)
      end
    end
  end
end

defimpl Phoenix.Param, for: Homelab.Backups.Backup do
  def to_param(backup), do: "#{backup.kind}_#{backup.name}"
end
