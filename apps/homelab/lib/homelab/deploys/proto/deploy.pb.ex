defmodule Homelab.Deploys.Proto.Deploy do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :id, 1, type: :int64
  field :commit_sha, 2, type: :string, json_name: "commitSha"
  field :commit_message, 3, type: :string, json_name: "commitMessage"
  field :state, 4, type: Homelab.Deploys.Proto.Deploy.State, enum: true
  field :started_at, 5, type: :string, json_name: "startedAt"
  field :finished_at, 6, type: :string, json_name: "finishedAt"
end