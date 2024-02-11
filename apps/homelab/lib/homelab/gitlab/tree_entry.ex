defmodule Homelab.GitLab.TreeEntry do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:id, :string)
    field(:mode, :string)
    field(:name, :string)
    field(:path, :string)
    field(:type, Ecto.Enum, values: [:tree, :blob])
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
    cast(data, params, [:id, :mode, :name, :path, :type])
  end
end
