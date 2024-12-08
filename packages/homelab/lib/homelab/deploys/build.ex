defmodule Homelab.Deploys.Build do
  use Ecto.Schema

  @primary_key {:id, :id, []}
  embedded_schema do
    field(:source, Ecto.Enum, values: [:github, :teamcity])
    field(:url, :string)
    field(:state, Ecto.Enum, values: [:success, :failure, :in_progress, :pending, :unknown])
    field(:percent, :integer)
    field(:queued_at, :utc_datetime)
    field(:started_at, :utc_datetime)
    field(:finished_at, :utc_datetime)
  end

  def completed?(%__MODULE__{state: state}) when state in [:success, :failure], do: true
  def completed?(%__MODULE__{}), do: false
end
