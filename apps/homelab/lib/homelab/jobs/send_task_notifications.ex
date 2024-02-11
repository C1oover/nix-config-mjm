defmodule Homelab.Jobs.SendTaskNotifications do
  use Oban.Worker, unique: [period: 60, states: [:available, :scheduled, :executing]]

  alias Homelab.Repo
  alias Homelab.Tasks.{Reminder, Task}
  alias Homelab.Tasks.Repo, as: TaskRepo

  import Ecto.Query

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    Task
    |> where([t], t.status == :pending and "reminder" in t.tags)
    |> TaskRepo.all()
    |> Enum.filter(&DateTime.before?(&1.next_notification, DateTime.utc_now()))
    |> Enum.each(&send_notification/1)
  end

  defp send_notification(task) do
    Homelab.Tasks.send_task_notification(task)

    reminder = Repo.get(Reminder, String.to_integer(task.reminder_id))

    task
    |> Task.notify_changeset(
      Timex.shift(task.next_notification, minutes: reminder.snooze_minutes)
    )
    |> TaskRepo.update!()
  end
end
