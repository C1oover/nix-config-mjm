defmodule Homelab.Tasks.LocalDatetime do
  use Ecto.Type

  def type(), do: :utc_datetime

  def cast(str) when is_binary(str) do
    str
    |> Timex.parse("{ISO:Extended:Z}")
    |> case do
      {:ok, %NaiveDateTime{} = dt} ->
        with {:ok, dt} <- DateTime.from_naive(dt, "America/Denver"),
             {:ok, dt} <- DateTime.shift_zone(dt, "Etc/UTC") do
          {:ok, DateTime.truncate(dt, :second)}
        else
          _ -> :error
        end

      {:ok, %DateTime{} = dt} ->
        {:ok, DateTime.truncate(dt, :second)}

      _ ->
        :error
    end
  end

  def cast(val), do: Ecto.Type.cast(:utc_datetime, val)

  def load(dt), do: Ecto.Type.load(:utc_datetime, dt)

  def dump(dt), do: Ecto.Type.dump(:utc_datetime, dt)
end
