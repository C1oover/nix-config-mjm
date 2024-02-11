defmodule Homelab.Deploys.Proto.Deploy.State do
  @moduledoc false
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :UNKNOWN, 0
  field :PENDING, 1
  field :IN_PROGRESS, 2
  field :SUCCESS, 3
  field :FAILURE, 4
  field :INACTIVE, 5
end