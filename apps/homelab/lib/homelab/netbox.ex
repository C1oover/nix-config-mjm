defmodule Homelab.NetBox do
  def query(query, variables \\ []) do
    case Tesla.post(client(), "/", %{query: query, variables: Map.new(variables)}) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: status, body: body}} ->
        {:error, {:unexpected_status, status, body}}

      {:error, err} ->
        {:error, err}
    end
  end

  def strip_mask(ip_addr) do
    [addr, _width] = String.split(ip_addr, "/")
    addr
  end

  defp client do
    config = Application.fetch_env!(:homelab, :netbox)

    middleware = [
      {Tesla.Middleware.BaseUrl, config[:url]},
      Tesla.Middleware.OpenTelemetry,
      Tesla.Middleware.PathParams,
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers, [{"authorization", "Token " <> config[:token]}]}
    ]

    Tesla.client(middleware)
  end
end
