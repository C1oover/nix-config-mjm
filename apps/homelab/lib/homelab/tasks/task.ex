defmodule Homelab.Tasks.Task do
  use Ecto.Schema
  import Ecto.Changeset

  alias Homelab.Tasks.TaskwarriorTimestamp

  @primary_key {:uuid, :binary_id, []}
  schema "all" do
    field(:id, :integer)
    field(:description, :string)
    field(:project, :string)
    field(:status, Ecto.Enum, values: [:pending, :completed, :deleted, :recurring, :waiting])
    field(:urgency, :float)
    field(:priority, Ecto.Enum, values: [:H, :M, :L])
    field(:tags, {:array, :string})
    field(:entry, TaskwarriorTimestamp)
    field(:modified, TaskwarriorTimestamp)
    field(:scheduled, TaskwarriorTimestamp)
    field(:start, TaskwarriorTimestamp)
    field(:end, TaskwarriorTimestamp)
    field(:due, TaskwarriorTimestamp)
    field(:until, TaskwarriorTimestamp)
    field(:wait, TaskwarriorTimestamp)
    field(:recur, :string)
    # TODO mask, imask if that seems valuable?
    field(:parent, :string)
    # TODO annotations
    # TODO depends (array that serializes to comma-separated string)
    field(:reminder_id, :string)
    field(:next_notification, TaskwarriorTimestamp)
  end

  def changeset(data, params) do
    data
    |> cast(params, [
      :description,
      :project,
      :scheduled,
      :status,
      :tags
    ])
  end

  def reminder_changeset(data, params) do
    data
    |> changeset(params)
    |> cast(params, [:reminder_id, :next_notification])
  end

  def notify_changeset(data, next_notification) do
    change(data, next_notification: next_notification)
  end
end
