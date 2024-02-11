defmodule HomelabWeb.AsyncData do
  import Phoenix.Component

  require Logger
  require OpenTelemetry.Tracer, as: Tracer

  alias Homelab.Otel

  defmacro __using__(_opts) do
    quote do
      import HomelabWeb.AsyncData, only: [fetch: 2, fetch: 3]

      Module.register_attribute(__MODULE__, :__async_tasks__, accumulate: true)
      Module.register_attribute(__MODULE__, :__async_intervals__, accumulate: true)
      Module.put_attribute(__MODULE__, :before_compile, HomelabWeb.AsyncData)

      on_mount {HomelabWeb.AsyncData, __MODULE__}

      def async_fetch(socket, task_ids) do
        HomelabWeb.AsyncData.async_fetch(socket, __MODULE__, task_ids)
      end

      defp fetch_and_assign_all(socket) do
        HomelabWeb.AsyncData.fetch_and_assign_all(socket, __MODULE__)
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def __task_ids__() do
        @__async_tasks__
      end

      def __async_intervals__() do
        @__async_intervals__
      end

      def assign_fetch_result(socket, task_id, result) do
        assign(socket, task_id, result)
      end
    end
  end

  defmacro fetch(task_id, opts, do: block) do
    define_fetch(task_id, opts, block)
  end

  defmacro fetch(task_id, opts \\ []) do
    {block, opts} = Keyword.pop(opts, :do, nil)

    define_fetch(task_id, opts, block)
  end

  defp define_fetch(task_id, opts, block) do
    interval = Keyword.get(opts, :interval)

    quote do
      task_id = unquote(task_id)
      interval = unquote(interval)

      Module.put_attribute(__MODULE__, :__async_tasks__, task_id)

      Module.put_attribute(
        __MODULE__,
        :__async_intervals__,
        {task_id, interval}
      )

      def __perform_fetch__(unquote(task_id), var!(socket)) do
        if false do
          var!(socket)
        else
          unquote(block)
        end
      end
    end
  end

  def on_mount(mod, _params, _session, socket) do
    for {task_id, interval} <- mod.__async_intervals__() do
      :timer.send_interval(interval, {:refresh, task_id})
    end

    socket =
      socket
      |> Phoenix.LiveView.attach_hook(:async_refresh, :handle_info, fn
        {:refresh, task_id}, socket ->
          {:halt, mod.async_fetch(socket, task_id)}

        _msg, socket ->
          {:cont, socket}
      end)
      |> Phoenix.LiveView.attach_hook(:handle_async_result, :handle_info, fn
        {ref, {:fetch, task_id, result}}, socket ->
          {:halt, handle_fetch_result(mod, ref, task_id, result, socket)}

        {:DOWN, ref, _, _, reason}, socket ->
          {:halt, handle_fetch_error(ref, reason, socket)}

        _msg, socket ->
          {:cont, socket}
      end)

    {:cont, assign(socket, :tasks, %{})}
  end

  def fetch_and_assign_all(socket, mod) do
    new_assigns =
      mod.__task_ids__()
      |> Enum.map(fn task_id ->
        Otel.async(fn -> {task_id, mod.__perform_fetch__(task_id, socket)} end)
      end)
      |> Task.await_many(10_000)

    Enum.reduce(new_assigns, socket, fn {task_id, result}, socket ->
      mod.assign_fetch_result(socket, task_id, result)
    end)
  end

  def async_fetch(socket, mod, task_ids) do
    update(
      socket,
      :tasks,
      fn tasks ->
        Enum.reduce(List.wrap(task_ids), tasks, fn task_id, tasks ->
          Map.put_new_lazy(tasks, task_id, fn ->
            span_ctx =
              Tracer.start_span(:async_fetch, %{
                attributes: %{
                  "task.module": inspect(mod),
                  "task.id": task_id
                }
              })

            {span_ctx,
             Otel.async_nolink(fn ->
               Tracer.set_current_span(span_ctx)
               {:fetch, task_id, mod.__perform_fetch__(task_id, socket)}
             end)}
          end)
        end)
      end
    )
  end

  defp handle_fetch_result(mod, ref, task_id, result, socket) do
    Process.demonitor(ref, [:flush])

    case current_task(socket, ref, task_id) do
      {span_ctx, _task} ->
        OpenTelemetry.Span.end_span(span_ctx)

        socket
        |> mod.assign_fetch_result(task_id, result)
        |> update(:tasks, &Map.delete(&1, task_id))

      nil ->
        Logger.info("Ignoring non-current task results", task_id: task_id, ref: ref)
        socket
    end
  end

  defp handle_fetch_error(ref, reason, socket) do
    with {task_id, {span_ctx, _task}} <-
           Enum.find(socket.assigns.tasks, fn {_task_id, {_span_ctx, task}} -> task.ref == ref end) do
      OpenTelemetry.Span.set_status(span_ctx, OpenTelemetry.status(:error, inspect(reason)))
      OpenTelemetry.Span.end_span(span_ctx)

      update(socket, :tasks, &Map.delete(&1, task_id))
    else
      _ ->
        Logger.error("Untracked background task failed with reason: #{inspect(reason)}",
          ref: ref
        )

        socket
    end
  end

  defp current_task(%{assigns: %{tasks: tasks}}, ref, task_id) do
    case Map.get(tasks, task_id) do
      {_span_ctx, %Task{ref: ^ref}} = result -> result
      _ -> nil
    end
  end
end
