defmodule NixosDeploy.Nix do
  def eval(opts) do
    args =
      ["eval", "--impure", "--json"] ++
        Enum.flat_map(opts, fn
          {:expr, expr} ->
            ["--expr", expr]
        end)

    case System.cmd("nix", args) do
      {output, 0} ->
        {:ok, :json.decode(output)}

      {output, exit_code} ->
        {:error, {:exit, exit_code, output}}
    end
  end

  def eval_jobs(opts) do
    args =
      Enum.flat_map(opts, fn
        {:expr, expr} ->
          ["--expr", expr]
      end)

    case System.cmd("nix-eval-jobs", ["--workers", "4"] ++ args, into: [], lines: 1024) do
      {result, 0} ->
        {:ok, Enum.map(result, &:json.decode/1)}

      {output, exit_code} ->
        {:error, {:exit, exit_code, Enum.join(output, "\n")}}
    end
  end

  def realise(drv_path, opts \\ []) do
    use_nom = Keyword.get(opts, :nom, false)

    if use_nom do
      System.shell(
        "nix-store --no-gc-warning --realise #{drv_path} --log-format internal-json -v |& nom --json"
      )
    else
      System.cmd("nix-store", ["--no-gc-warning", "--realise", drv_path])
    end
    |> case do
      {output, 0} ->
        {:ok, String.trim(output)}

      {output, exit_code} ->
        {:error, {:exit, exit_code, output}}
    end
  end

  def copy_closure(path, opts) do
    ssh_opts = opts |> Keyword.get(:ssh_options, []) |> Enum.join(" ")

    case System.cmd(
           "nix",
           [
             "copy",
             "--no-check-sigs",
             "--to",
             opts[:to],
             path
           ],
           env: %{"NIX_SSHOPTS" => ssh_opts}
         ) do
      {_output, 0} ->
        :ok

      {output, exit_code} ->
        {:error, {:exit, exit_code, output}}
    end
  end

  def diff(old_path, new_path) do
    case System.cmd("nvd", ["--color=always", "diff", old_path, new_path], into: IO.stream()) do
      {_output, 0} ->
        :ok

      {_, exit_code} ->
        {:error, {:exit, exit_code, ""}}
    end
  end
end
