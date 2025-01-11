defmodule NixosDeploy.Host.Local do
  alias NixosDeploy.Host

  @behaviour Host

  @impl true
  def copy_closure(_host, _path) do
    :ok
  end

  @impl true
  def run_command(_host, command, args, opts \\ []) do
    case Rambo.run("sudo", [command | args], opts) do
      {:ok, %{out: output}} ->
        {:ok, output}

      {:error, %{status: exit_code, out: output}} ->
        {:error, {:exit, exit_code, output}}
    end
  end
end
