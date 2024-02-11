defmodule Homelab.Deploys.Proto.GetDeployReportResponse do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :report, 1, type: Homelab.Deploys.Proto.Report
end