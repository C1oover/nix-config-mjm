defmodule Homelab.Tasks.StringArray do
  use Ecto.Type

  def type(), do: {:array, :string}

  def cast(strs) when is_list(strs), do: {:ok, strs}

  def cast(str) when is_binary(str) do
    String.split(str, ",", trim: true)
  end

  def cast(_), do: :error

  def load(strs) when is_list(strs), do: {:ok, strs}
  def load(_), do: :error

  def dump(strs) when is_list(strs) do
    {:ok, Enum.join(strs, ",")}
  end

  def dump(_), do: :error
end
