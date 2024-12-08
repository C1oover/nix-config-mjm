defmodule HomelabWeb.TaskLive.TaskList do
  defstruct rows: [], selected: nil

  alias Phoenix.LiveView.AsyncResult
  alias __MODULE__

  def new([]), do: %TaskList{}
  def new([first | _] = rows), do: %TaskList{rows: rows, selected: first.uuid}

  def put_rows(%AsyncResult{} = result, new_rows) do
    update_async_result(result, &put_rows(&1, new_rows))
  end

  def put_rows(%TaskList{}, []), do: %TaskList{}

  def put_rows(%TaskList{rows: old_rows, selected: selected} = task_list, new_rows) do
    task_list = %{task_list | rows: new_rows}

    if Enum.any?(new_rows, &(&1.uuid == selected)) do
      task_list
    else
      old_index = Enum.find_index(old_rows, &(&1.uuid == selected)) || 0
      new_index = min(old_index, length(new_rows) - 1)
      new_uuid = Enum.at(new_rows, new_index).uuid

      %{task_list | selected: new_uuid}
    end
  end

  def select(%AsyncResult{} = result, uuid) do
    update_async_result(result, &select(&1, uuid))
  end

  def select(%TaskList{} = task_list, uuid) do
    if Enum.any?(task_list.rows, &(&1.uuid == uuid)) do
      %{task_list | selected: uuid}
    else
      task_list
    end
  end

  def select_up(%AsyncResult{} = result), do: update_async_result(result, &select_up/1)

  def select_up(%TaskList{} = task_list) do
    update_index(task_list, &max(&1 - 1, 0))
  end

  def select_down(%AsyncResult{} = result), do: update_async_result(result, &select_down/1)

  def select_down(%TaskList{} = task_list) do
    update_index(task_list, &min(&1 + 1, length(task_list.rows) - 1))
  end

  defp update_index(task_list, func) do
    idx = Enum.find_index(task_list.rows, &(&1.uuid == task_list.selected))
    new_idx = func.(idx)
    %{task_list | selected: Enum.at(task_list.rows, new_idx).uuid}
  end

  defp update_async_result(%AsyncResult{ok?: true, result: %TaskList{} = tl} = result, func) do
    AsyncResult.ok(result, func.(tl))
  end
end
