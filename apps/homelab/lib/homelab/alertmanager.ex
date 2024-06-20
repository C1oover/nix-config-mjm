defmodule Homelab.Alertmanager do
  use Tesla

  plug(Tesla.Middleware.BaseUrl, "http://alertmanager.service.consul:9093")
  plug(Tesla.Middleware.OpenTelemetry)
  plug(Tesla.Middleware.PathParams)
  plug(Tesla.Middleware.JSON)

  alias Homelab.Alertmanager.Alert

  def list_alerts() do
    case get("/api/v2/alerts", query: [silenced: "false"], opts: [path_params: []]) do
      {:ok, %{status: 200, body: alerts}} when is_list(alerts) ->
        alerts |> Alert.decode() |> then(&{:ok, &1})

      {:ok, %{status: 200}} ->
        {:error, :unexpected_data}

      {:ok, %{status: status}} ->
        {:error, {:unexpected_status, status}}

      {:error, err} ->
        {:error, err}
    end
  end
end
