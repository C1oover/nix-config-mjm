defmodule Homelab.Tasks.Reminder do
  use Ecto.Schema
  import Ecto.Changeset

  alias Homelab.Tasks.LocalDatetime

  schema "reminders" do
    field(:description, :string)
    field(:project, :string)
    field(:started_at, :utc_datetime)
    field(:notify_at, LocalDatetime)
    field(:snooze_minutes, :integer)
    field(:recurrence, :map)
    field(:recurrence_string, :string, virtual: true)

    timestamps()
  end

  def changeset(data, params) do
    data
    |> cast(params, [:description, :project, :notify_at, :snooze_minutes, :recurrence])
    |> cast_recurrence_string(params)
    |> validate_required([:description, :notify_at])
  end

  def fire_changeset(data) do
    data
    |> change(started_at: DateTime.truncate(DateTime.utc_now(), :second))
    |> set_next_notify_at()
  end

  def with_recurrence_string(%{recurrence: %{} = recurrence} = reminder) do
    str = Enum.map_join(recurrence, " ", fn {key, value} -> "#{key}:#{value}" end)

    %{reminder | recurrence_string: str}
  end

  def with_recurrence_string(reminder), do: reminder

  defp cast_recurrence_string(changeset, params) do
    changeset = cast(changeset, params, [:recurrence_string])

    case fetch_change(changeset, :recurrence_string) do
      {:ok, ""} ->
        put_change(changeset, :recurrence, nil)

      {:ok, str} ->
        recurrence =
          str
          |> String.split()
          |> Enum.map(fn component ->
            case String.split(component, ":", parts: 2) do
              [key, value] ->
                case Integer.parse(value) do
                  {value, _rest} -> {key, value}
                  :error -> nil
                end

              _ ->
                nil
            end
          end)
          |> Enum.reject(&is_nil/1)
          |> Map.new()

        put_change(changeset, :recurrence, recurrence)

      _ ->
        changeset
    end
  end

  defp set_next_notify_at(changeset) do
    case get_field(changeset, :recurrence) do
      nil ->
        changeset

      recurrence ->
        prev_notify_at = fetch_field!(changeset, :notify_at)
        started_at = fetch_field!(changeset, :started_at)

        shift_params =
          recurrence
          |> Map.take(~w[years months weeks days hours minutes])
          |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

        put_change(
          changeset,
          :notify_at,
          advance_next_notify_at(prev_notify_at, shift_params, started_at)
        )
    end
  end

  # Protect against blackholing a reminder if we try to shift its notify_at forward
  # and its still before its last started_at. This would only happen if the app is
  # not running for some time, such that it misses the job to create reminder tasks
  # for a while.
  defp advance_next_notify_at(current, shift_params, started_at) do
    case DateTime.compare(current, started_at) do
      :gt -> current
      _ -> advance_next_notify_at(Timex.shift(current, shift_params), shift_params, started_at)
    end
  end
end
