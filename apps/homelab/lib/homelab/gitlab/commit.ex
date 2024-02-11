defmodule Homelab.GitLab.Commit do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:id, :string)
    field(:message, :string)
  end

  def decode(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_action!(:decode)
  end

  def to_commit(%__MODULE__{} = commit) do
    %Homelab.Deploys.Commit{
      sha: commit.id,
      message: commit.message
    }
  end

  def apply(%Homelab.Deploys.Deploy{} = deploy, %__MODULE__{} = commit) do
    %{deploy | commit: to_commit(commit)}
  end

  def changeset(data, params) do
    cast(data, params, [:id, :message])
  end
end
