defmodule Homelab.Deploys do
  require OpenTelemetry.Tracer, as: Tracer

  alias Homelab.GitLab
  alias Homelab.Deploys.Deploy

  def get_latest_infra_build(), do: get_latest_gitlab_build("mjm/nix-config")

  def list_recent_infra_deployments() do
    with {:ok, deployments} <-
           GitLab.list_project_deployments("mjm/nix-config",
             per_page: 20,
             order_by: "created_at",
             sort: "desc"
           ) do
      deployments
      |> Enum.filter(& &1.deployable)
      |> GitLab.Deployment.to_deploy()
      |> Deploy.deactivate_old_deploys()
    else
      err ->
        raise "error fetching infra deployments: #{inspect(err)}"
    end
  end

  defp get_latest_gitlab_build(repo) do
    Tracer.with_span :get_latest_gitlab_build, %{attributes: %{"gitlab.repo": repo}} do
      with {:ok, [pipeline]} <-
             GitLab.list_project_pipelines(
               repo,
               per_page: 1,
               source: "push",
               ref: "main"
             ),
           {:ok, pipeline} <- GitLab.get_pipeline(repo, pipeline.id) do
        GitLab.Pipeline.to_build(pipeline)
      else
        err ->
          raise "error fetching latest gitlab build: #{inspect(err)}"
      end
    end
  end
end
