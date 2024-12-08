defmodule NixosDeploy.Host.SSH do
  alias NixosDeploy.Host
  alias NixosDeploy.Nix

  @behaviour Host

  @impl true
  def copy_closure(host, path) do
    Nix.copy_closure(path, to: "ssh-ng://#{ssh_target(host)}", ssh_options: host.opts[:ssh_opts])
  end

  @impl true
  def run_command(host, command, args) do
    ssh_args = [ssh_target(host)] ++ host.opts[:ssh_opts] ++ ["--", "sudo", command] ++ args

    case System.cmd("ssh", ssh_args) do
      {output, 0} ->
        {:ok, output}

      {output, exit_code} ->
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
