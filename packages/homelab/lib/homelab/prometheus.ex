defmodule Homelab.Prometheus do
  use Tesla

  plug(Tesla.Middleware.BaseUrl, "http://prometheus.service.consul:9090")
  plug(Tesla.Middleware.OpenTelemetry)
  plug(Tesla.Middleware.PathParams)
  plug(Tesla.Middleware.JSON)

  def list_alerts() do
    case get("/api/v1/alerts", opts: [path_params: []]) do
      {:ok, %{status: 200, body: %{"data" => %{"alerts" => alerts}}}} -> {:ok, alerts}
      {:ok, %{status: 200}} -> {:error, :unexpected_data}
      {:ok, %{status: status}} -> {:error, {:unexpected_status, status}}
      {:error, err} -> {:error, err}
    end
  end
end
