defmodule Homelab.Backups.Backup do
  use Ecto.Schema

  embedded_schema do
    field(:kind, Ecto.Enum, values: [:restic])
    field(:name, :string)
    field(:time, :utc_datetime)
    field(:location, Ecto.Enum, values: [:onsite, :offsite])
    field(:repository_name, :string)
    field(:hostname, :string)
  end
end
