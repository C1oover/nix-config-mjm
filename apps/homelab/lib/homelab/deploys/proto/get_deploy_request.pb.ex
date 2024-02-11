defmodule Homelab.Deploys.Proto.GetDeployRequest do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :deploy_id, 1, type: :int64, json_name: "deployId"
end