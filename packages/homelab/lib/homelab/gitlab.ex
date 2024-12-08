defmodule Homelab.GitLab do
  alias __MODULE__

  def list_project_pipelines(project_id, opts \\ []) do
    url = "/projects/:id/pipelines"
    params = [id: project_id]

    case Tesla.get(client(), url, opts: [path_params: params], query: opts) do
      {:ok, %{status: 200, body: pipelines}} ->
        pipelines |> GitLab.Pipeline.decode() |> then(&{:ok, &1})

      {:ok, %{status: status}} ->
        {:error, {:unexpected_status, status}}

      {:error, error} ->
        {:error, error}
    end
  end

  def get_pipeline(project_id, pipeline_id, opts \\ []) do
    url = "/projects/:id/pipelines/:pipeline_id"
    params = [id: project_id, pipeline_id: pipeline_id]

    case Tesla.get(client(), url, opts: [path_params: params], query: opts) do
      {:ok, %{status: 200, body: pipeline}} ->
        pipeline |> GitLab.Pipeline.decode() |> then(&{:ok, &1})

      {:ok, %{status: status}} ->
        {:error, {:unexpected_status, status}}

      {:error, error} ->
        {:error, error}
    end
  end

  def list_project_deployments(project_id, opts \\ []) do
    url = "/projects/:id/deployments"
    params = [id: project_id]

    case Tesla.get(client(), url, opts: [path_params: params], query: opts) do
      {:ok, %{status: 200, body: deployments}} ->
        deployments |> GitLab.Deployment.decode(project_id) |> then(&{:ok, &1})

      {:ok, %{status: status}} ->
        {:error, {:unexpected_status, status}}

      {:error, error} ->
        {:error, error}
    end
  end

  def get_repository_file_raw(project_id, path, opts \\ []) do
    url = "/projects/:id/repository/files/:file_path/raw"
    params = [id: project_id, file_path: path]

    case Tesla.get(client(), url, opts: [path_params: params], query: opts) do
      {:ok, %{status: 200, body: contents}} -> {:ok, contents}
      {:ok, %{status: 404}} -> {:error, :not_found}
      {:ok, %{status: status}} -> {:error, {:unexpected_status, status}}
      {:error, error} -> {:error, error}
    end
  end

  def update_repository_file(project_id, path, content, opts \\ []) do
    url = "/projects/:id/repository/files/:file_path"
    params = [id: project_id, file_path: path]

    body = opts |> Map.new() |> Map.put(:content, content)

    case Tesla.put(client(), url, body, opts: [path_params: params]) do
      {:ok, %{status: 200, body: body}} -> {:ok, body}
      {:ok, %{status: status}} -> {:error, {:unexpected_status, status}}
      {:error, error} -> {:error, error}
    end
  end

  def list_repository_tree(project_id, opts \\ []) do
    url = "/projects/:id/repository/tree"
    params = [id: project_id]

    case Tesla.get(client(), url, opts: [path_params: params], query: opts) do
      {:ok, %{status: 200, body: entries}} ->
        entries |> GitLab.TreeEntry.decode() |> then(&{:ok, &1})

      {:ok, %{status: status}} ->
        {:error, {:unexpected_status, status}}

      {:error, error} ->
        {:error, error}
    end
  end

  def create_commit(project_id, opts \\ []) do
    url = "/projects/:id/repository/commits"
    params = [id: project_id]
    body = Map.new(opts)

    case Tesla.post(client(), url, body, opts: [path_params: params]) do
      {:ok, %{status: 201, body: body}} -> {:ok, body}
      {:ok, %{status: status}} -> {:error, {:unexpected_status, status}}
      {:error, error} -> {:error, error}
    end
  end

  def client do
    token = Application.fetch_env!(:homelab, :gitlab_token)

    middleware = [
      {Tesla.Middleware.BaseUrl, "http://10.0.2.32/api/v4"},
      Tesla.Middleware.OpenTelemetry,
      Tesla.Middleware.PathParams,
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers,
       [{"authorization", "Bearer " <> token}, {"user-agent", "homelab"}]}
    ]

    Tesla.client(middleware)
  end
end
