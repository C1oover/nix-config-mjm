defmodule Homelab.Deploys.Commit do
  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field(:sha, :string)
    field(:message, :string)
  end
end
