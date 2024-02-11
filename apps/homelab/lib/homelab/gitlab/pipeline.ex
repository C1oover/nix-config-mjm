defmodule Homelab.GitLab.Pipeline do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, []}
  embedded_schema do
    field(:status, :string)
    field(:sha, :string)
    field(:web_url, :string)
    field(:created_at, :utc_datetime)
    field(:updated_at, :utc_datetime)
    field(:started_at, :utc_datetime)
    field(:finished_at, :utc_datetime)
  end

  def decode(params) when is_list(params) do
    Enum.map(params, &decode/1)
  end

  def decode(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_action!(:decode)
  end

  def to_build(%__MODULE__{} = build) do
    %Homelab.Deploys.Build{
      source: :gitlab,
      id: build.id,
      url: build.web_url,
      state: build_state(build.status),
      queued_at: build.created_at,
      started_at: build.started_at,
      finished_at: build.finished_at
    }
  end

  def changeset(data, params) do
    cast(data, params, [
      :id,
      :status,
      :sha,
      :web_url,
      :created_at,
      :updated_at,
      :started_at,
      :finished_at
    ])
  end

  defp build_state("running"), do: :in_progress
  defp build_state(status) when status in ~w(success skipped), do: :success
  defp build_state(status) when status in ~w(failed canceled), do: :failure

  defp build_state(status)
       when status in ~w(created waiting_for_resource preparing pending),
       do: :pending

  defp build_state(_), do: :unknown
end
