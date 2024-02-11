defmodule Homelab.Backups.Borg.Stats do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:compressed_size, :integer)
    field(:deduplicated_size, :integer)
    field(:original_size, :integer)
    field(:nfiles, :integer)
  end

  def to_stats(%__MODULE__{} = stats) do
    %Homelab.Backups.Backup.Detail.Stats{
      compressed_size: stats.compressed_size,
      deduplicated_size: stats.deduplicated_size,
      original_size: stats.original_size,
      num_files: stats.nfiles
    }
  end

  def changeset(data, params) do
    cast(data, params, [:compressed_size, :deduplicated_size, :original_size, :nfiles])
  end
end
