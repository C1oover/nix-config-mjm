defmodule NixosDeploy.Host do
  defstruct ~w[
	  name
	  kind
	  drv_path
	  out_path
	  deploy_config
	  reboot_needed
	  opts
	]a

  @type t() :: %__MODULE__{
          name: String.t(),
          kind: atom(),
          drv_path: String.t(),
          out_path: nil | String.t(),
          deploy_config: map(),
          reboot_needed: nil | boolean(),
          opts: keyword()
        }

  @callback copy_closure(t(), String.t()) :: :ok | {:error, term()}
  @callback run_command(t(), String.t(), [String.t()], keyword()) ::
              {:ok, String.t()} | {:error, term()}

  def copy_closure(host, path) do
    host.kind.copy_closure(host, path)
  end

  def run_command(host, command, args, opts \\ []) do
    host.kind.run_command(host, command, args, opts)
  end
end
