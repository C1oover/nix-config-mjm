defmodule NixosDeploy.Host.Local do
  alias NixosDeploy.Host

  @behaviour Host

  @impl true
  def copy_closure(_host, _path) do
    :ok
  end

  @impl true
  def run_command(_host, command, args) do
    case System.cmd("sudo", [command | args]) do
      {output, 0} ->
        {:ok, output}

      {output, exit_code} ->
        {:error, {:exit, exit_code, output}}
    end
  end
end
