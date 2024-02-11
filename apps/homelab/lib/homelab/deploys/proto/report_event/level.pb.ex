defmodule Homelab.Deploys.Proto.ReportEvent.Level do
  @moduledoc false
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :UNKNOWN, 0
  field :INFO, 1
  field :WARNING, 2
  field :ERROR, 3
end