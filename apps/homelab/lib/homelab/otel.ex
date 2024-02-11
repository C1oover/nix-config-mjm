defmodule Homelab.Otel do
  def async(fun) do
    ctx = OpenTelemetry.Ctx.get_current()

    Task.async(fn ->
      OpenTelemetry.Ctx.attach(ctx)
      fun.()
    end)
  end

  def async_supervised(fun, options \\ []) do
    ctx = OpenTelemetry.Ctx.get_current()

    Task.Supervisor.async(
      Homelab.TaskSupervisor,
      fn ->
        OpenTelemetry.Ctx.attach(ctx)
        fun.()
      end,
      options
    )
  end

  def async_nolink(fun, options \\ []) do
    ctx = OpenTelemetry.Ctx.get_current()

    Task.Supervisor.async_nolink(
      Homelab.TaskSupervisor,
      fn ->
        OpenTelemetry.Ctx.attach(ctx)
        fun.()
      end,
      options
    )
  end
end
