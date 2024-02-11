defmodule Homelab.Tasks.Adapter.Connection do
  use GenServer

  require OpenTelemetry.Tracer, as: Tracer

  def start_link(config) do
    __MODULE__
    |> GenServer.start_link(config, name: __MODULE__)
    |> case do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl GenServer
  def init(_config) do
    {:ok, %{}}
  end

  def export(query, params) do
    GenServer.call(__MODULE__, {:export, query, params})
  end

  def execute(args) do
    GenServer.call(__MODULE__, {:execute, args})
  end

  def insert(fields) do
    GenServer.call(__MODULE__, {:insert, fields})
  end

  def update(filters, fields) do
    GenServer.call(__MODULE__, {:update, filters, fields})
  end

  def delete(filters) do
    GenServer.call(__MODULE__, {:delete, filters})
  end

  def done(filters) do
    GenServer.call(__MODULE__, {:done, filters})
  end

  def sync() do
    GenServer.call(__MODULE__, :sync)
  end

  @impl GenServer
  def handle_call({:export, query, params}, _from, state) do
    filters =
      Enum.map(query.filters, fn
        {:tags, {:param, idx}} -> "+#{Enum.at(params, idx)}"
        {:tags, value} -> "+#{value}"
        {field, {:param, idx}} -> "#{field}:#{Enum.at(params, idx)}"
        {field, value} -> "#{field}:#{value}"
        str when is_binary(str) -> str
      end)

    {:ok, results} = command_json(filters ++ ["export", query.report, "rc.json.array=on"])
    {:reply, results, state}
  end

  @impl GenServer
  def handle_call({:execute, args}, _from, state) do
    {:reply, command(args), state}
  end

  @impl GenServer
  def handle_call({:insert, fields}, _from, state) do
    fields = Enum.map(fields, fn {field, value} -> "#{field}:#{value}" end)

    {:ok, _} = command(["add" | fields])
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_call({:update, filters, fields}, _from, state) do
    filters = Enum.map(filters, fn {field, value} -> "#{field}:#{value}" end)
    fields = Enum.map(fields, fn {field, value} -> "#{field}:#{value}" end)

    {:ok, _} = command(filters ++ ["modify"] ++ fields ++ ["rc.recurrence.confirmation=off"])
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_call({:delete, filters}, _from, state) do
    filters = Enum.map(filters, fn {field, value} -> "#{field}:#{value}" end)

    {:ok, _} = command(filters ++ ["delete", "rc.confirmation=off"])
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_call({:done, filters}, _from, state) do
    filters = Enum.map(filters, fn {field, value} -> "#{field}:#{value}" end)

    {:ok, _} = command(filters ++ ["done"])
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_call(:sync, _from, state) do
    # intentionally ignore errors, since we might not having syncing configured
    command(["sync"])
    {:reply, :ok, state}
  end

  defp command_json(args) do
    Tracer.with_span :run_tw_command, %{
      attributes: %{"tw.args": inspect(args), "tw.json": true}
    } do
      with {result_str, 0} <- System.cmd("task", args, env: task_env()) do
        Jason.decode(result_str)
      else
        {output, code} when is_integer(code) ->
          {:error, {:bad_code, code, output}}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp command(args) do
    Tracer.with_span :run_tw_command, %{
      attributes: %{"tw.args": inspect(args), "tw.json": false}
    } do
      with {result_str, 0} <- System.cmd("task", args, env: task_env()) do
        {:ok, result_str}
      else
        {output, code} when is_integer(code) ->
          {:error, {:bad_code, code, output}}
      end
    end
  end

  defp task_env() do
    [{"TZ", "America/Denver"}]
  end
end
