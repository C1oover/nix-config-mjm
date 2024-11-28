defmodule NixosDeploy.Consul do
  def get_service_health(service, node) do
    Req.get!("http://consul.service.consul:8500/v1/health/service/:service",
      params: [filter: "Node.Node == \"#{node}\""],
      path_params: [service: service]
    ).body
  end
end
