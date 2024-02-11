defmodule Homelab.GitLab.Environment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, []}
  embedded_schema do
    field(:name, :string)
  end

  def decode(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_action!(:decode)
  end

  def changeset(data, params) do
    cast(data, params, [:id, :name])
  end
end
