defmodule Homelab.Backups.Borg.ArchiveSummary do
  use Ecto.Schema
  import Ecto.Changeset

  alias Homelab.Backups

  embedded_schema do
    field(:name, :string)
    field(:start, :naive_datetime)
  end

  def decode(params) when is_list(params) do
    Enum.map(params, &decode/1)
  end

  def decode(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_action!(:decode)
  end

  def to_backup(summaries) when is_list(summaries) do
    Enum.map(summaries, &to_backup/1)
  end

  def to_backup(%__MODULE__{} = summary) do
    %Backups.Backup{
      kind: :borg,
      id: summary.id,
      name: summary.name,
      time: Backups.Borg.convert_to_utc(summary.start)
    }
  end

  def changeset(data, params) do
    cast(data, params, [:id, :name, :start])
  end
end
