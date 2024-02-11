defmodule Homelab.Tasks.TaskwarriorTimestamp do
  use Ecto.Type

  def type(), do: :utc_datetime

  def cast(ts) when is_binary(ts) do
    with {:error, _} <- HumanTime.relative(ts, from: Timex.now("America/Denver")),
         {:error, _} <- Timex.parse(ts, "{ISO:Basic:Z}") do
      :error
    end
  end

  def cast(%DateTime{} = ts), do: {:ok, ts}
  def cast(_), do: :error

  def load(ts) when is_binary(ts) do
    Timex.parse(ts, "{ISO:Basic:Z}")
  end

  def load(%DateTime{} = ts), do: {:ok, ts}
  def load(_), do: :error

  def dump(%DateTime{} = ts) do
    ts
    |> DateTime.truncate(:second)
    |> Timex.format("{ISO:Basic:Z}")
  end

  def dump(_), do: :error
end
