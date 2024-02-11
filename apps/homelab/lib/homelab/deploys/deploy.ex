defmodule Homelab.Deploys.Deploy do
  use Ecto.Schema

  alias Homelab.Deploys.Commit

  @primary_key {:id, :id, []}
  embedded_schema do
    field(:source, Ecto.Enum, values: [:github, :gitlab])
    field(:repo, :string)
    field(:job, :string)
    field(:url, :string)
    field(:environment, :string)

    field(:state, Ecto.Enum,
      values: [:success, :failure, :inactive, :in_progress, :pending, :unknown]
    )

    field(:created_at, :utc_datetime)
    field(:started_at, :utc_datetime)
    field(:finished_at, :utc_datetime)

    embeds_one(:commit, Commit)
  end

  def deactivate_old_deploys(deploys) do
    deploys
    |> Enum.reduce({[], %{}}, fn deploy, {deploys, successes} ->
      key = {deploy.source, deploy.repo, deploy.job}

      case {deploy.state, Map.has_key?(successes, key)} do
        {:success, true} ->
          {[%{deploy | state: :inactive} | deploys], successes}

        {:success, false} ->
          {[deploy | deploys], Map.put(successes, key, deploy)}

        _ ->
          {[deploy | deploys], successes}
      end
    end)
    |> elem(0)
    |> Enum.reverse()
  end

  def deploy_time(%__MODULE__{created_at: ts, started_at: nil, finished_at: nil}), do: ts
  def deploy_time(%__MODULE__{started_at: ts, finished_at: nil}), do: ts
  def deploy_time(%__MODULE__{finished_at: ts}), do: ts
end
