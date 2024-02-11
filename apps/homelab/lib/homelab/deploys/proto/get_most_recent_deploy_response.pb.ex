defmodule Homelab.Deploys.Proto.GetMostRecentDeployResponse do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :deploy, 1, type: Homelab.Deploys.Proto.Deploy
end