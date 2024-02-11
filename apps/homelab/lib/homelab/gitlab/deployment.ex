defmodule Homelab.GitLab.Deployment do
  use Ecto.Schema
  import Ecto.Changeset

  alias Homelab.GitLab

  @primary_key {:id, :id, []}
  embedded_schema do
    field(:project, :string)
    field(:sha, :string)
    field(:status, :string)
    field(:created_at, :utc_datetime)
    field(:updated_at, :utc_datetime)

    embeds_one(:deployable, GitLab.Job)
    embeds_one(:environment, GitLab.Environment)
  end

  def decode(params, project) when is_list(params) do
    Enum.map(params, &decode(&1, project))
  end

  def decode(params, project) do
    %__MODULE__{project: project}
    |> changeset(params)
    |> apply_action!(:decode)
  end

  def to_deploy(deploys) when is_list(deploys) do
    Enum.map(deploys, &to_deploy/1)
  end

  def to_deploy(%__MODULE__{} = deploy) do
    %Homelab.Deploys.Deploy{
      source: :gitlab,
      id: deploy.id,
      repo: deploy.project,
      job: deploy.deployable.name,
      url: deploy.deployable.web_url,
      environment: friendly_environment(deploy.environment),
      state: deploy_state(deploy.status),
      created_at: deploy.created_at,
      started_at: deploy.deployable.started_at,
      finished_at: deploy.deployable.finished_at,
      commit: GitLab.Commit.to_commit(deploy.deployable.commit)
    }
  end

  def changeset(data, params) do
    data
    |> cast(params, [:id, :sha, :status, :created_at, :updated_at])
    |> cast_embed(:deployable)
    |> cast_embed(:environment)
  end

  defp deploy_state("success"), do: :success
  defp deploy_state("running"), do: :in_progress
  defp deploy_state(status) when status in ~w(failed canceled skipped), do: :failure
  defp deploy_state(status) when status in ~w(created blocked), do: :pending
  defp deploy_state(_), do: :unknown

  defp friendly_environment(%{name: "production"}), do: nil

  defp friendly_environment(environment) do
    environment.name
    |> String.replace_prefix("production/", "")
  end
end
