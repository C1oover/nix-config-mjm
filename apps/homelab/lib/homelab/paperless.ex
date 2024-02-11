defmodule Homelab.Paperless do
  def list_documents_by_tag(tag, opts \\ []) do
    opts =
      opts
      |> Keyword.put(:tags__name__iexact, tag)
      |> Keyword.put_new(:page_size, 200)

    case Tesla.get(client(), "/api/documents/", opts: [path_params: []], query: opts) do
      {:ok, %{body: %{"results" => results}}} ->
        {:ok, results}

      {:error, err} ->
        {:error, err}
    end
  end

  defp client do
    token = Application.fetch_env!(:homelab, :paperless_token)

    middleware = [
      {Tesla.Middleware.BaseUrl, "http://paperless.service.consul:28981"},
      Tesla.Middleware.OpenTelemetry,
      Tesla.Middleware.PathParams,
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers, [{"authorization", "Token " <> token}]}
    ]

    Tesla.client(middleware)
  end
end
