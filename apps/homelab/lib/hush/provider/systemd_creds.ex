defmodule Hush.Provider.SystemdCreds do
  @behaviour Hush.Provider

  @impl true
  def load(_config), do: :ok

  @impl true
  def fetch(key) do
    case System.get_env("CREDENTIALS_DIRECTORY") do
      nil -> {:error, :no_creds_dir}
      creds_dir -> creds_dir |> Path.join(key) |> File.read()
    end
  end
end
