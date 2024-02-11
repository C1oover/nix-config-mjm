defmodule Homelab.Tasks do
  alias Homelab.Repo
  alias __MODULE__.Repo, as: TaskRepo
  alias __MODULE__.{Reminder, Task}

  import Ecto.Query

  def sync() do
    TaskRepo.sync()
  end

  def list_tasks(opts \\ []) do
    source = if report = opts[:report], do: {report, Task}, else: Task
    TaskRepo.all(source)
  end

  def list_reminders() do
    Reminder
    |> where([r], r.notify_at >= ^DateTime.utc_now())
    |> order_by(:notify_at)
    |> Repo.all()
  end

  def get_task(uuid) do
    TaskRepo.get(Task, uuid)
  end

  def get_reminder(id) do
    Reminder
    |> Repo.get(id)
    |> Reminder.with_recurrence_string()
  end

  def create_task(task_str) do
    # this is definitely not sufficient but it will do for now
    args = String.split(task_str)

    with {:ok, _} <- TaskRepo.execute(["add" | args]) do
      from(t in Task, where: "LATEST" in t.tags)
      |> TaskRepo.one()
      |> then(&{:ok, &1})
    end
  end

  def create_reminder(params) do
    %Reminder{}
    |> Reminder.changeset(params)
    |> Repo.insert()
  end

  def modify_task(task, task_str) do
    # this is definitely not sufficient but it will do for now
    args = String.split(task_str)

    with {:ok, _} <- TaskRepo.execute([task.uuid, "modify" | args]) do
      {:ok, TaskRepo.reload!(task)}
    end
  end

  def update_reminder(reminder, params) do
    reminder
    |> Reminder.changeset(params)
    |> Repo.update()
  end

  def delete_task(task) do
    TaskRepo.delete(task)
  end

  def add_tags(task, tags) do
    tags_to_add =
      tags
      |> MapSet.new()
      |> MapSet.difference(MapSet.new(task.tags))
      |> Enum.into([])

    task
    |> Task.changeset(%{tags: task.tags ++ tags_to_add})
    |> TaskRepo.update()
  end

  def remove_tags(task, tags) do
    task
    |> Task.changeset(%{tags: Enum.reject(task.tags, &Enum.member?(tags, &1))})
    |> TaskRepo.update()
  end

  def mark_done(task) do
    task
    |> Task.changeset(%{status: :completed})
    |> TaskRepo.update()
  end

  def reschedule_task(task, date) do
    task
    |> Task.changeset(%{scheduled: date})
    |> TaskRepo.update()
  end

  def send_task_notification(task) do
    HomelabWeb.Endpoint.broadcast!("notifications", "notification", %{
      "tag" => task.uuid,
      "text" => task.description
    })
  end
end
