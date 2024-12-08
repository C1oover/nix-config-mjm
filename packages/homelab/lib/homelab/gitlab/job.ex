defmodule Homelab.GitLab.Job do
  use Ecto.Schema
  import Ecto.Changeset

  alias Homelab.GitLab

  @primary_key {:id, :id, []}
  embedded_schema do
    field(:name, :string)
    field(:stage, :string)
    field(:status, :string)
    field(:web_url, :string)
    field(:created_at, :utc_datetime)
    field(:started_at, :utc_datetime)
    field(:finished_at, :utc_datetime)

    embeds_one(:commit, GitLab.Commit)
    embeds_one(:pipeline, GitLab.Pipeline)
  end

  def changeset(data, params) do
    data
    |> cast(params, [
      :id,
      :name,
      :stage,
      :status,
      :web_url,
      :created_at,
      :started_at,
      :finished_at
    ])
    |> cast_embed(:commit)
    |> cast_embed(:pipeline)
  end
end
