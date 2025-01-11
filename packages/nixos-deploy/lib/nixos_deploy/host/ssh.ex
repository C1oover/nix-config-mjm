defmodule NixosDeploy.Host.SSH do
  alias NixosDeploy.Host
  alias NixosDeploy.Nix

  @behaviour Host

  @impl true
  def copy_closure(host, path) do
    Nix.copy_closure(path, to: "ssh-ng://#{ssh_target(host)}", ssh_options: host.opts[:ssh_opts])
  end

  @impl true
  def run_command(host, command, args, opts \\ []) do
    ssh_args = [ssh_target(host)] ++ host.opts[:ssh_opts] ++ ["--", "sudo", command] ++ args

    case Rambo.run("ssh", ssh_args, opts) do
      {:ok, %{out: output}} ->
        {:ok, output}

      {:error, %{status: exit_code, out: output}} ->
        {:error, {:exit, exit_code, output}}
    end
  end

  @spec ssh_target(Host.t()) :: String.t()
  defp ssh_target(host) do
    target_host = host.deploy_config["targetHost"]
    target_user = host.deploy_config["targetUser"]

    "#{target_user}@#{target_host}"
  end
end
