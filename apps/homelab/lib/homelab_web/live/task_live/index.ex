defmodule HomelabWeb.TaskLive.Index do
  use HomelabWeb, :live_view

  alias Homelab.Tasks.Reminder
  alias HomelabWeb.TaskLive.TaskList

  embed_templates "index/*"

  def mount(_params, _session, socket) do
    :timer.send_interval(5_000, :update_now)
    :timer.send_interval(30_000, :update_tasks)

    socket
    |> assign_now()
    |> assign(:new_task_form, nil)
    |> assign(:reschedule_form, nil)
    |> assign(:edit_form, nil)
    |> assign(:new_reminder_form, nil)
    |> assign(:edit_reminder_form, nil)
    |> assign(:reminders, Homelab.Tasks.list_reminders())
    |> then(&{:ok, &1})
  end

  def handle_params(params, _uri, socket) do
    report = Map.get(params, "report", "ready")

    socket
    |> assign(:report, report)
    |> assign_async(:tasks, fn -> {:ok, %{tasks: TaskList.new(synced_tasks(report))}} end)
    |> then(&{:noreply, &1})
  end

  defp assign_now(socket) do
    assign(socket, :now, DateTime.utc_now())
  end

  defp synced_tasks(report) do
    Homelab.Tasks.sync()
    list_tasks(report)
  end

  defp list_tasks(report) do
    Homelab.Tasks.list_tasks(report: report)
  end

  def handle_info(:update_now, socket) do
    {:noreply, assign_now(socket)}
  end

  def handle_info(:update_tasks, %{assigns: %{tasks: %{loading: nil} = tasks}} = socket) do
    report = socket.assigns.report

    {:noreply,
     assign_async(socket, :tasks, fn ->
       tasks
       |> case do
         %{ok?: true, result: old_tasks} ->
           TaskList.put_rows(old_tasks, synced_tasks(report))

         _ ->
           TaskList.new(synced_tasks(report))
       end
       |> then(&{:ok, %{tasks: &1}})
     end)}
  end

  def handle_info(:update_tasks, socket) do
    {:noreply, socket}
  end

  def handle_event("change_report", %{"report" => report}, socket) do
    socket
    |> push_patch(to: ~p"/tasks/#{report}")
    |> then(&{:noreply, &1})
  end

  def handle_event("done", %{"done" => "true", "task_uuid" => task_uuid}, socket) do
    mark_done(socket, task_uuid)
  end

  def handle_event("show_new_task", _, socket) do
    show_new_task(socket)
  end

  def handle_event("cancel_new_task", _, socket) do
    {:noreply, assign(socket, new_task_form: nil)}
  end

  def handle_event("submit_new_task", %{"task" => task_str}, socket) do
    case Homelab.Tasks.create_task(task_str) do
      {:ok, task} ->
        socket
        |> put_flash(:info, "Added task \"#{task.description}\".")
        |> assign(:new_task_form, nil)
        |> update_tasks(fn tasks ->
          tasks
          |> TaskList.put_rows(list_tasks(socket.assigns.report))
          |> TaskList.select(task.uuid)
        end)
        |> then(&{:noreply, &1})

      {:error, _err} ->
        {:noreply, put_flash(socket, :error, "Couldn't add task.")}
    end
  end

  def handle_event("show_new_reminder", _params, socket) do
    socket
    |> assign(
      :new_reminder_form,
      %Reminder{}
      |> Reminder.changeset(%{
        notify_at: DateTime.utc_now(),
        snooze_minutes: 10
      })
      |> to_form()
    )
    |> then(&{:noreply, &1})
  end

  def handle_event("cancel_new_reminder", _params, socket) do
    {:noreply, assign(socket, :new_reminder_form, nil)}
  end

  def handle_event("change_new_reminder", %{"reminder" => params}, socket) do
    form =
      %Reminder{}
      |> Reminder.changeset(params)
      |> to_form()

    {:noreply, assign(socket, :new_reminder_form, form)}
  end

  def handle_event("submit_new_reminder", %{"reminder" => params}, socket) do
    case Homelab.Tasks.create_reminder(params) do
      {:ok, reminder} ->
        socket
        |> put_flash(:info, "Created reminder \"#{reminder.description}\".")
        |> assign(:new_reminder_form, nil)
        |> assign(:reminders, Homelab.Tasks.list_reminders())
        |> then(&{:noreply, &1})

      {:error, changeset} ->
        socket
        |> assign(:new_reminder_form, to_form(changeset))
        |> put_flash(:error, "Couldn't add reminder.")
        |> then(&{:noreply, &1})
    end
  end

  def handle_event("show_reschedule", %{"task_uuid" => task_uuid}, socket) do
    show_reschedule_task(socket, task_uuid)
  end

  def handle_event("cancel_reschedule", _, socket) do
    {:noreply, assign(socket, reschedule_form: nil)}
  end

  def handle_event("change_reschedule", params, socket) do
    form = params |> Map.take(["uuid", "date"]) |> to_form()
    {:noreply, assign(socket, reschedule_form: form)}
  end

  def handle_event("reschedule", %{"uuid" => task_uuid, "date" => date}, socket) do
    task = Homelab.Tasks.get_task(task_uuid)

    case Homelab.Tasks.reschedule_task(task, date) do
      {:ok, task} ->
        socket
        |> put_flash(:info, "Rescheduled task \"#{task.description}\".")
        |> assign(:reschedule_form, nil)
        |> update_tasks()
        |> then(&{:noreply, &1})

      {:error, _err} ->
        {:noreply, put_flash(socket, :error, "Couldn't reschedule task.")}
    end
  end

  def handle_event("show_edit", %{"task_uuid" => task_uuid}, socket) do
    show_edit_task(socket, task_uuid)
  end

  def handle_event("cancel_edit", _, socket) do
    {:noreply, assign(socket, edit_form: nil)}
  end

  def handle_event("change_edit", params, socket) do
    form = params |> Map.take(["uuid", "task"]) |> to_form()
    {:noreply, assign(socket, edit_form: form)}
  end

  def handle_event("edit", %{"uuid" => task_uuid, "task" => task_str}, socket) do
    task = Homelab.Tasks.get_task(task_uuid)

    case Homelab.Tasks.modify_task(task, task_str) do
      {:ok, task} ->
        socket
        |> put_flash(:info, "Updated task \"#{task.description}\".")
        |> assign(:edit_form, nil)
        |> update_tasks()
        |> then(&{:noreply, &1})

      {:error, _err} ->
        {:noreply, put_flash(socket, :error, "Couldn't save task.")}
    end
  end

  def handle_event("show_edit_reminder", %{"id" => id}, socket) do
    form = id |> Homelab.Tasks.get_reminder() |> Reminder.changeset(%{}) |> to_form()

    {:noreply, assign(socket, :edit_reminder_form, form)}
  end

  def handle_event("cancel_edit_reminder", _params, socket) do
    {:noreply, assign(socket, :edit_reminder_form, nil)}
  end

  def handle_event("change_edit_reminder", %{"reminder" => params}, socket) do
    form =
      socket.assigns.edit_reminder_form.data
      |> Reminder.changeset(params)
      |> to_form()

    {:noreply, assign(socket, :edit_reminder_form, form)}
  end

  def handle_event("submit_edit_reminder", %{"reminder" => params}, socket) do
    reminder = Homelab.Tasks.get_reminder(params["id"])

    case Homelab.Tasks.update_reminder(reminder, params) do
      {:ok, reminder} ->
        socket
        |> put_flash(:info, "Updated reminder \"#{reminder.description}\".")
        |> assign(:edit_reminder_form, nil)
        |> assign(:reminders, Homelab.Tasks.list_reminders())
        |> then(&{:noreply, &1})

      {:error, _err} ->
        {:noreply, put_flash(socket, :error, "Couldn't save reminder.")}
    end
  end

  def handle_event("delete_task", %{"task_uuid" => task_uuid}, socket) do
    task = Homelab.Tasks.get_task(task_uuid)

    case Homelab.Tasks.delete_task(task) do
      {:ok, task} ->
        socket
        |> put_flash(:info, "Deleted task \"#{task.description}\".")
        |> update_tasks()
        |> then(&{:noreply, &1})

      {:error, _err} ->
        {:noreply, put_flash(socket, :error, "Couldn't delete task.")}
    end
  end

  def handle_event("delete_reminder", %{"id" => id}, socket) do
    reminder = Homelab.Tasks.get_reminder(id)

    case Homelab.Tasks.delete_reminder(reminder) do
      {:ok, reminder} ->
        socket
        |> put_flash(:info, "Deleted reminder \"#{reminder.description}\".")
        |> assign(:reminders, Homelab.Tasks.list_reminders())
        |> then(&{:noreply, &1})

      {:error, _err} ->
        {:noreply, put_flash(socket, :error, "Couldn't delete reminder.")}
    end
  end

  def handle_event("toggle_next", %{"task_uuid" => task_uuid}, socket) do
    toggle_next_task(socket, task_uuid)
  end

  def handle_event("add_child", %{"task_uuid" => task_uuid}, socket) do
    add_child_task(socket, task_uuid)
  end

  def handle_event("add_weekly_meal_tasks", _params, socket) do
    case Homelab.Tasks.Templates.add_weekly_meal_tasks() do
      :ok ->
        socket
        |> put_flash(:info, "Added weekly meal tasks.")
        |> update_tasks()
        |> then(&{:noreply, &1})

      {:error, _err} ->
        {:noreply, put_flash(socket, :error, "Couldn't add tasks.")}
    end
  end

  def handle_event("add_laundry_tasks", _params, socket) do
    case Homelab.Tasks.Templates.add_laundry_tasks() do
      :ok ->
        socket
        |> put_flash(:info, "Added laundry tasks.")
        |> update_tasks()
        |> then(&{:noreply, &1})

      {:error, _err} ->
        {:noreply, put_flash(socket, :error, "Couldn't add tasks.")}
    end
  end

  def handle_event("keydown", %{"key" => "a"}, socket) do
    show_new_task(socket)
  end

  def handle_event("keydown", %{"key" => "A"}, socket) do
    with_selection(socket, &add_child_task/2)
  end

  def handle_event("keydown", %{"key" => "C"}, socket) do
    with_selection(socket, fn socket, uuid ->
      {:noreply, push_event(socket, "copy_task_uuid", %{uuid: uuid})}
    end)
  end

  def handle_event("keydown", %{"key" => "d"}, socket) do
    with_selection(socket, &mark_done/2)
  end

  def handle_event("keydown", %{"key" => "e"}, socket) do
    with_selection(socket, &show_edit_task/2)
  end

  def handle_event("keydown", %{"key" => "j"}, socket) do
    {:noreply, update(socket, :tasks, &TaskList.select_down/1)}
  end

  def handle_event("keydown", %{"key" => "k"}, socket) do
    {:noreply, update(socket, :tasks, &TaskList.select_up/1)}
  end

  def handle_event("keydown", %{"key" => "N"}, socket) do
    with_selection(socket, fn socket, uuid ->
      task = Homelab.Tasks.get_task(uuid)
      Homelab.Tasks.send_task_notification(task)

      {:noreply, socket}
    end)
  end

  def handle_event("keydown", %{"key" => "s"}, socket) do
    with_selection(socket, &show_reschedule_task/2)
  end

  def handle_event("keydown", %{"key" => "t"}, socket) do
    with_selection(socket, &toggle_next_task/2)
  end

  def handle_event("keydown", %{"key" => "x"}, socket) do
    with_selection(socket, fn socket, uuid ->
      {:noreply, push_event(socket, "confirm_delete_task", %{uuid: uuid})}
    end)
  end

  def handle_event("keydown", _params, socket) do
    {:noreply, socket}
  end

  defp show_new_task(socket) do
    form = to_form(%{"task" => ""})
    {:noreply, assign(socket, new_task_form: form)}
  end

  defp show_edit_task(socket, task_uuid) do
    form = to_form(%{"uuid" => task_uuid, "task" => ""})
    {:noreply, assign(socket, edit_form: form)}
  end

  defp show_reschedule_task(socket, task_uuid) do
    form = to_form(%{"uuid" => task_uuid, "date" => ""})
    {:noreply, assign(socket, reschedule_form: form)}
  end

  defp mark_done(socket, task_uuid) do
    task = Homelab.Tasks.get_task(task_uuid)
    {:ok, _task} = Homelab.Tasks.mark_done(task)

    {:noreply, update_tasks(socket)}
  end

  defp add_child_task(socket, task_uuid) do
    form = to_form(%{"task" => " depends:#{task_uuid}"})
    {:noreply, assign(socket, new_task_form: form)}
  end

  defp toggle_next_task(socket, task_uuid) do
    task = Homelab.Tasks.get_task(task_uuid)

    {verb, result} =
      if Enum.member?(task.tags, "next") do
        {"Deprioritized", Homelab.Tasks.remove_tags(task, ["next"])}
      else
        {"Prioritized", Homelab.Tasks.add_tags(task, ["next"])}
      end

    case result do
      {:ok, task} ->
        socket
        |> put_flash(:info, "#{verb} task \"#{task.description}\".")
        |> update_tasks()
        |> then(&{:noreply, &1})

      {:error, _err} ->
        {:noreply, put_flash(socket, :error, "Couldn't update task.")}
    end
  end

  defp with_selection(socket, func) do
    case socket.assigns.tasks do
      %{ok?: true, result: %TaskList{selected: uuid}} ->
        func.(socket, uuid)

      _ ->
        {:noreply, socket}
    end
  end

  defp update_tasks(socket, fun \\ nil) do
    fun =
      fun ||
        fn task_list ->
          TaskList.put_rows(task_list, list_tasks(socket.assigns.report))
        end

    socket
    |> cancel_async(:tasks)
    |> update(:tasks, fun)
  end
end
