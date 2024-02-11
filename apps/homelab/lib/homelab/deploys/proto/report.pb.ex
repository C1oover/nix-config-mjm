defmodule Homelab.Deploys.Proto.Report do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :deploy_id, 1, type: :int64, json_name: "deployId"
  field :commit_sha, 2, type: :string, json_name: "commitSha"
  field :commit_message, 3, type: :string, json_name: "commitMessage"
  field :events, 4, repeated: true, type: Homelab.Deploys.Proto.ReportEvent
end