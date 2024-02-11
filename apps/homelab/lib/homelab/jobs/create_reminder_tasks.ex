defmodule Homelab.Jobs.CreateReminderTasks do
  use Oban.Worker, unique: [period: 60, states: [:available, :scheduled, :executing]]

  alias Homelab.Repo
  alias Homelab.Tasks.{Reminder, Task}
  alias Homelab.Tasks.Repo, as: TaskRepo

  import Ecto.Query

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    Reminder
    |> where(
      [r],
      (is_nil(r.started_at) or r.notify_at > r.started_at) and
        r.notify_at <= ^DateTime.utc_now()
    )
    |> Repo.all()
    |> Enum.each(&create_task/1)

    # After we've created any necessary tasks, send notifications for all tasks
    # that need them (including ones created previously).
    %{}
    |> Homelab.Jobs.SendTaskNotifications.new()
    |> Oban.insert!()

    :ok
  end

  defp create_task(reminder) do
    %Task{}
    |> Task.reminder_changeset(%{
      description: reminder.description,
      project: reminder.project,
      tags: ["reminder"],
      scheduled: reminder.notify_at,
      reminder_id: Integer.to_string(reminder.id),
      next_notification: reminder.notify_at
    })
    |> TaskRepo.insert!()

    reminder
    |> Reminder.fire_changeset()
    |> Repo.update!()
  end
end
