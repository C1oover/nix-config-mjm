defmodule Homelab.Paperless do
  def count_documents_by_tag(tag, opts \\ []) do
    opts = Keyword.put(opts, :tags__name__iexact, tag)

    with {:ok, %{body: %{"count" => count}}} <-
           Tesla.get(client(), "/api/documents/", opts: [path_params: []], query: opts) do
      {:ok, count}
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
