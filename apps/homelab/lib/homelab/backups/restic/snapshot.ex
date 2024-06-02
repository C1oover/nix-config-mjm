defmodule Homelab.Backups.Restic.Snapshot do
  use Ecto.Schema
  import Ecto.Changeset

  alias Homelab.Backups

  embedded_schema do
    field(:short_id, :string)
    field(:hostname, :string)
    field(:time, :utc_datetime)
  end

  def decode(params) when is_list(params) do
    Enum.map(params, &decode/1)
  end

  def decode(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_action!(:decode)
  end

  def to_backup(snapshots, location, repository) when is_list(snapshots) do
    Enum.map(snapshots, &to_backup(&1, location, repository))
  end

  def to_backup(%__MODULE__{} = snapshot, location, repository) do
    %Backups.Backup{
      kind: :restic,
      id: snapshot.id,
      name: snapshot.short_id,
      time: snapshot.time,
      location: location,
      repository_name: repository,
      hostname: snapshot.hostname
    }
  end

  def changeset(data, params) do
    cast(data, params, [:id, :short_id, :hostname, :time])
  end
end
