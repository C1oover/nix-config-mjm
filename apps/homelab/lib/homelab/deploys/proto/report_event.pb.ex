defmodule Homelab.Deploys.Proto.ReportEvent do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :timestamp, 1, type: Google.Protobuf.Timestamp
  field :level, 2, type: Homelab.Deploys.Proto.ReportEvent.Level, enum: true
  field :summary, 3, type: :string
  field :description, 4, type: :string
end