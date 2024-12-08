defmodule Homelab.Alertmanager.Alert do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:annotations, :map)
    field(:labels, :map)
    field(:endsAt, :utc_datetime)
    field(:startsAt, :utc_datetime)
    field(:updatedAt, :utc_datetime)
  end

  def decode(params) when is_list(params) do
    Enum.map(params, &decode/1)
  end

  def decode(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_action!(:decode)
  end

  def changeset(data, params) do
    cast(data, params, [:annotations, :labels, :endsAt, :startsAt, :updatedAt])

    # TODO pull description and summary out of annotations
  end
end
