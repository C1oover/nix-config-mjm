defmodule NixosDeploy do
  require Logger
  alias NixosDeploy.Consul
  alias NixosDeploy.Host
  alias NixosDeploy.Nix

  def main(args) do
    :logger.remove_handler(:default)

    :logger.add_handler(:stderr, :logger_std_h, %{
      config: %{type: :standard_error},
      formatter: Logger.default_formatter()
    })

    {options, [command | args]} =
      OptionParser.parse!(args,
        strict: [
          plans: :string,
          ssh_identity_file: :string
        ],
        aliases: [
          f: :plans
        ]
      )

    handle_command(command, args, options)
  end

  def handle_command("deploy", args, opts) do
    plans_file = Keyword.get(opts, :plans, "plans.nix")

    {plan, evaled_nodes} = eval_nodes(plans_file, args, opts)

    pushed_nodes =
      evaled_nodes
      |> Enum.filter(&(&1.kind == Host.SSH))
      |> Task.async_stream(__MODULE__, :build_node, [], timeout: :infinity, ordered: false)
      |> Task.async_stream(__MODULE__, :push_node, [], timeout: :infinity, ordered: false)
      |> Task.async_stream(__MODULE__, :push_to_attic, [], timeout: :infinity, ordered: false)
      |> Task.async_stream(__MODULE__, :check_node_reboot_needed, [],
        timeout: 30_000,
        ordered: false
      )
      |> Enum.map(fn {:ok, node} -> node end)

    deploy_plan(plan, pushed_nodes)

    Logger.info("deploy completed")
  end

  def handle_command("diff", args, opts) do
    plans_file = Keyword.get(opts, :plans, "plans.nix")

    {plan, evaled_nodes} = eval_nodes(plans_file, args, opts)

    evaled_nodes
    |> Task.async_stream(__MODULE__, :build_node, [], timeout: :infinity, ordered: false)
    |> Task.async_stream(__MODULE__, :push_to_attic, [], timeout: :infinity, ordered: false)
    # build all nodes, then only push and diff the ones that are reachable via ssh
    |> Enum.filter(fn {:ok, node} -> node.kind == Host.SSH end)
    |> Task.async_stream(__MODULE__, :push_node, [], timeout: :infinity, ordered: false)
    |> Task.async_stream(__MODULE__, :diff_node, [], timeout: 60_000, ordered: false)
    |> Enum.map(fn {:ok, result} -> result end)
    |> aggregate_diffs()
    |> :json.encode()
    |> IO.write()
  end

  def handle_command("apply-local", _args, opts) do
    plans_file = Keyword.get(opts, :plans, "plans.nix")

    plans_file
    |> eval_local_node(opts)
    |> build_local_node()
    |> diff_local_node()
    |> apply_local_node()
  end

  def eval_nodes(plans_file, hostnames, opts) do
    Logger.info("evaluating plans")

    ssh_opts =
      case Keyword.fetch(opts, :ssh_identity_file) do
        {:ok, file} -> ["-o", "IdentityFile=#{file}"]
        :error -> []
      end ++ ["-o", "BatchMode=yes", "-T"]

    names_to_include =
      "builtins.fromJSON #{inspect(hostnames |> :json.encode() |> IO.iodata_to_binary())}"

    {:ok, paths} = Nix.eval_jobs(file: plans_file, args: [namesToInclude: names_to_include])
    paths_by_attr = Map.new(paths, &{&1["attr"], &1["drvPath"]})
    {config_drv, paths_by_attr} = Map.pop(paths_by_attr, "configJson")
    {:ok, config_path} = Nix.realise(config_drv)

    %{"phases" => phases, "deployment" => deploy_config} =
      config_path |> File.read!() |> :json.decode()

    paths_by_attr
    |> Enum.filter(fn {name, _} -> Enum.any?(phases, &(name in &1["nodes"])) end)
    |> Enum.map(fn {name, drv_path} ->
      kind = if deploy_config[name]["targetHost"] == :null, do: Host.Local, else: Host.SSH

      %Host{
        name: name,
        kind: kind,
        drv_path: drv_path,
        deploy_config: deploy_config[name],
        opts: [ssh_opts: ssh_opts]
      }
    end)
    |> then(&{phases, &1})
  end

  def eval_local_node(plans_file, _opts) do
    {:ok, hostname} = :inet.gethostname()
    hostname = to_string(hostname)

    eval_expr =
      "let config = (import ./#{plans_file} {}).#{hostname}; in { drv = config.drvPath; out = config.outPath; }"

    {:ok, %{"drv" => drv_path, "out" => out_path}} = Nix.eval(expr: eval_expr)

    %Host{
      name: hostname,
      kind: Host.Local,
      drv_path: drv_path,
      out_path: out_path,
      deploy_config: %{},
      opts: []
    }
  end

  def build_node(node) do
    Logger.info("building #{node.name} from #{node.drv_path}")

    case Nix.realise(node.drv_path) do
      {:ok, out_path} ->
        %{node | out_path: out_path}

      {:error, {:exit, exit_code, output}} ->
        raise "Building node #{node.name} failed with exit code #{exit_code}: #{output}"
    end
  end

  def build_local_node(node) do
    Logger.info("building #{node.name} from #{node.drv_path}")

    case Nix.realise(node.drv_path, nom: true) do
      {:ok, _} ->
        node

      {:error, {:exit, exit_code, output}} ->
        raise "Building node #{node.name} failed with exit code #{exit_code}: #{output}"
    end
  end

  # TODO use watch-store for this
  def push_to_attic({:ok, node}) do
    Logger.info("pushing #{node.name} to attic cache")

    # TODO retry this multiple times
    case System.cmd("attic", ["push", "homelab", node.out_path]) do
      {_, 0} ->
        node

      {output, exit_code} ->
        raise "Pushing #{node.name} to attic cache failed with exit code #{exit_code}: #{output}"
    end
  end

  def push_node({:ok, node}) do
    Logger.info("pushing to #{node.name}")

    case Host.copy_closure(node, node.out_path) do
      :ok ->
        node

      {:error, {:exit, exit_code, output}} ->
        raise "Pushing node #{node.name} failed with exit code #{exit_code}: #{output}"
    end
  end

  def diff_node({:ok, node}) do
    Logger.info("diffing #{node.name} against current system")

    case Host.run_command(node, "#{node.out_path}/bin/nvd-json", [
           "diff",
           "/run/current-system",
           node.out_path
         ]) do
      {:ok, output} ->
        {node, output}

      {:error, {:exit, exit_code, output}} ->
        raise "Diffing #{node.name} failed with exit code #{exit_code}: #{output}"
    end
  end

  def diff_local_node(node) do
    :ok =
      case Nix.diff("/run/current-system", node.out_path) do
        :ok ->
          :ok

        {:error, {:exit, exit_code, output}} ->
          raise "Diffing failed with exit code #{exit_code}: #{output}"
      end

    node = check_node_reboot_needed({:ok, node})

    if node.reboot_needed do
      Logger.info("reboot needed")
    end

    node
  end

  def check_node_reboot_needed({:ok, node}) do
    Logger.info("checking if #{node.name} requires a reboot")

    case Host.run_command(
           node,
           "#{node.out_path}/bin/nvd-json",
           ["reboot-check", node.out_path]
         ) do
      {:ok, output} ->
        %{"reboot_needed" => reboot_needed} = :json.decode(output)
        %{node | reboot_needed: reboot_needed}

      {:error, {:exit, exit_code, output}} ->
        raise "Checking if node #{node.name} requires reboot failed with exit code #{exit_code}: #{output}"
    end
  end

  def deploy_plan(plan, nodes) do
    nodes_by_name = Map.new(nodes, &{&1.name, &1})

    Enum.each(plan, fn phase ->
      nodes =
        phase["nodes"]
        |> Enum.map(&nodes_by_name[&1])
        |> Enum.reject(&is_nil/1)

      deploy_phase(phase["name"], nodes)
    end)
  end

  def deploy_phase(_, []), do: :ok

  def deploy_phase(name, nodes) do
    Logger.info("deploying #{name} phase")

    Enum.each(nodes, &deploy_node/1)

    Logger.info("deployed #{name} phase")
  end

  @system_profile "/nix/var/nix/profiles/system"

  def deploy_node(node) do
    Logger.info("deploying #{node.name}")

    Logger.info("setting new system profile for #{node.name}")

    case Host.run_command(
           node,
           "nix-env",
           ["--profile", @system_profile, "--set", node.out_path]
         ) do
      {:ok, _} ->
        :ok

      {:error, {:exit, exit_code, output}} ->
        raise "Setting system profile for #{node.name} failed with exit code #{exit_code}: #{output}"
    end

    goal = if node.reboot_needed, do: "boot", else: "switch"
    Logger.info("activating new system for #{node.name} via #{goal}")

    case Host.run_command(
           node,
           "#{@system_profile}/bin/switch-to-configuration",
           [goal]
         ) do
      {:ok, _} ->
        :ok

      {:error, {:exit, exit_code, output}} ->
        raise "Activating system for #{node.name} failed with exit code #{exit_code}: #{output}"
    end

    if node.reboot_needed and node.deploy_config["rebootAutomatically"] do
      Logger.info("rebooting #{node.name}")
      :ok = reboot_node(node)
    end

    consul_check_count = length(node.deploy_config["consulChecks"])

    if consul_check_count > 0 do
      Logger.info("waiting for #{node.name} to be healthy")

      node.deploy_config["consulChecks"]
      |> Task.async_stream(__MODULE__, :wait_for_consul_check, [node],
        timeout: 600_000,
        max_concurrency: consul_check_count
      )
      |> Stream.run()

      Logger.info("#{node.name} is healthy")
    end

    Logger.info("deployed #{node.name} successfully")

    node
  end

  def apply_local_node(node) do
    goal = if node.reboot_needed, do: "boot", else: "switch"

    IO.write("Apply changes with #{goal} goal? ")

    result =
      case IO.read(:line) do
        :eof -> System.halt(1)
        {:error, _reason} -> System.halt(1)
        "y" <> _rest -> :yes
        "Y" <> _rest -> :yes
        _other -> :no
      end

    if result != :yes do
      System.halt(0)
    end

    Logger.info("setting new system profile for #{node.name}")

    case Host.run_command(
           node,
           "nix-env",
           ["--profile", @system_profile, "--set", node.out_path]
         ) do
      {:ok, _} ->
        :ok

      {:error, {:exit, exit_code, output}} ->
        raise "Setting system profile for #{node.name} failed with exit code #{exit_code}: #{output}"
    end

    case Host.run_command(
           node,
           "#{@system_profile}/bin/switch-to-configuration",
           [goal]
         ) do
      {:ok, _} ->
        :ok

      {:error, {:exit, exit_code, output}} ->
        raise "Activating system for #{node.name} failed with exit code #{exit_code}: #{output}"
    end

    if node.reboot_needed do
      Logger.info("reboot to apply changes")
    end
  end

  def reboot_node(node) do
    Logger.info("rebooting #{node.name}")

    {:ok, old_id} = get_boot_id(node)

    case Host.run_command(node, "reboot", []) do
      {:ok, _} ->
        :ok

      {:error, {:exit, 255, _}} ->
        :ok

      {:error, {:exit, exit_code, output}} ->
        raise "Initiating reboot for #{node.name} failed with exit code #{exit_code}: #{output}"
    end

    Logger.info("waiting for #{node.name} to reboot")

    :ok = wait_for_reboot(node, old_id)

    Logger.info("rebooted #{node.name}")
  end

  def wait_for_reboot(node, old_boot_id) do
    case get_boot_id(node) do
      {:ok, new_boot_id} when old_boot_id != new_boot_id ->
        :ok

      _ ->
        Process.sleep(2_000)
        wait_for_reboot(node, old_boot_id)
    end
  end

  def wait_for_consul_check(service, node) do
    Process.sleep(20_000)

    service_health = Consul.get_service_health(service, node.name)

    all_passing =
      length(service_health) > 0 and
        Enum.all?(service_health, fn %{"Checks" => checks} ->
          Enum.all?(checks, &(&1["Status"] == "passing"))
        end)

    if all_passing do
      :ok
    else
      wait_for_consul_check(service, node)
    end
  end

  def aggregate_diffs(nodes_with_diffs) do
    dir = Path.join(System.tmp_dir!(), "nixos-deploy-#{:erlang.phash2(make_ref())}")
    File.mkdir_p!(dir)

    paths =
      for {node, diff} <- nodes_with_diffs do
        path = Path.join(dir, "#{node.name}.json")
        File.write!(path, diff)
        path
      end

    case System.cmd("nvd-json", ["aggregate" | paths]) do
      {output, 0} ->
        File.rm_rf!(dir)
        :json.decode(output)

      {output, exit_code} ->
        File.rm_rf!(dir)
        raise "Aggregating diffs failed with exit code #{exit_code}: #{output}"
    end
  end

  defp get_boot_id(node) do
    with {:ok, output} <-
           Host.run_command(node, "cat", ["/proc/sys/kernel/random/boot_id"]) do
      {:ok, String.trim(output)}
    end
  end
end
