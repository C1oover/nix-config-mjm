defmodule Homelab.Deploys.Proto.ListRecentDeploysResponse do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :deploys, 1, repeated: true, type: Homelab.Deploys.Proto.Deploy
end