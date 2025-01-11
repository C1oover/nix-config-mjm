defmodule NixosDeploy.Nix do
  def eval(opts) do
    args =
      ["eval", "--impure", "--json"] ++
        Enum.flat_map(opts, fn
          {:expr, expr} ->
            ["--expr", expr]

          {:file, path} ->
            ["--file", path]
        end)

    case Rambo.run("nix", args) do
      {:ok, %{out: output}} ->
        {:ok, :json.decode(output)}

      {:error, %{status: exit_code, out: output}} ->
        {:error, {:exit, exit_code, output}}
    end
  end

  def eval_jobs(opts) do
    args =
      Enum.flat_map(opts, fn
        {:expr, expr} ->
          ["--expr", expr]

        {:file, path} ->
          [path]

        {:args, args} ->
          Enum.flat_map(args, fn {key, value} ->
            ["--arg", to_string(key), value]
          end)
      end)

    case Rambo.run("nix-eval-jobs", ["--workers", "4"] ++ args) do
      {:ok, %{out: result}} ->
        result
        |> String.split("\n", trim: true)
        |> Enum.map(&:json.decode/1)
        |> then(&{:ok, &1})

      {:error, %{status: exit_code, out: output}} ->
        {:error, {:exit, exit_code, output}}
    end
  end

  def realise(drv_path, opts \\ []) do
    use_nom = Keyword.get(opts, :nom, false)

    {cmd, args} =
      if use_nom do
        # TODO maybe stream this via Rambo?
        {"/bin/sh",
         [
           "-c",
           "nix-store --no-gc-warning --realise #{drv_path} --log-format internal-json -v |& nom --json"
         ]}
      else
        {"nix-store", ["--no-gc-warning", "--realise", drv_path]}
      end

    case Rambo.run(cmd, args) do
      {:ok, %{out: output}} ->
        {:ok, String.trim(output)}

      {:error, %{status: exit_code, out: output}} ->
        {:error, {:exit, exit_code, output}}
    end
  end

  def copy_closure(path, opts) do
    ssh_opts = opts |> Keyword.get(:ssh_options, []) |> Enum.join(" ")

    case Rambo.run(
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
      {:ok, _} ->
        :ok

      {:error, %{status: exit_code, out: output}} ->
        {:error, {:exit, exit_code, output}}
    end
  end

  def diff(old_path, new_path) do
    case Rambo.run("nvd", ["--color=always", "diff", old_path, new_path], log: true) do
      {:ok, _} ->
        :ok

      {:error, %{status: exit_code, out: output}} ->
        {:error, {:exit, exit_code, output}}
    end
  end
end
