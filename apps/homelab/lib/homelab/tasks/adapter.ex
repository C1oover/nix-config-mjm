defmodule Homelab.Tasks.Adapter do
  @behaviour Ecto.Adapter
  @behaviour Ecto.Adapter.Queryable
  @behaviour Ecto.Adapter.Schema

  alias __MODULE__.{Connection, Query}

  @impl Ecto.Adapter
  defmacro __before_compile__(_env) do
    quote do
      defdelegate sync(), to: Homelab.Tasks.Adapter.Connection
      defdelegate execute(args), to: Homelab.Tasks.Adapter.Connection
    end
  end

  @impl Ecto.Adapter
  def init(options) do
    {:ok, Connection.child_spec(options), %{}}
  end

  @impl Ecto.Adapter
  def ensure_all_started(_options, _type) do
    {:ok, []}
  end

  @impl Ecto.Adapter
  def checked_out?(_meta) do
    false
  end

  @impl Ecto.Adapter
  def checkout(_meta, _opts, fun) do
    fun.()
  end

  @impl Ecto.Adapter
  def dumpers(_, type), do: [type]

  @impl Ecto.Adapter
  def loaders(_, type), do: [type]

  @impl Ecto.Adapter.Queryable
  def stream(_, _, _, _, _) do
    :error
  end

  @impl Ecto.Adapter.Queryable
  def prepare(type, %Ecto.Query{} = query) do
    {:nocache, {type, Query.from_ecto(query)}}
  end

  @impl Ecto.Adapter.Queryable
  def execute(_adapter_meta, query_meta, {:nocache, {:all, query}}, params, _opts) do
    results = Connection.export(query, params)

    types = types_from_query_meta(query_meta)
    decoded = decode_result(results, types)

    {length(decoded), decoded}
  end

  defp types_from_query_meta(%{select: %{from: {_, {_, {_, schema}, _, types}}}}) do
    Enum.map(types, fn {field, type} -> {schema.__schema__(:field_source, field), type} end)
  end

  defp decode_result(result, types) when is_list(result) do
    Enum.map(result, &decode_result(&1, types))
  end

  defp decode_result(%{} = result, types) do
    Enum.map(types, fn {field, type} ->
      result |> Map.get(Atom.to_string(field)) |> decode_type(type)
    end)
  end

  defp decode_type(nil, {:array, :string}), do: []
  defp decode_type(value, _type), do: value

  @impl Ecto.Adapter.Schema
  def insert(_adapter_meta, %{schema: schema}, fields, _on_conflict, returning, _opts) do
    fields = Keyword.replace_lazy(fields, :tags, &Enum.join(&1, ","))
    :ok = Connection.insert(fields)

    if Enum.empty?(returning) do
      {:ok, []}
    else
      # this is kind of gross, maybe Connection.insert should do this for us
      [result] = Connection.export(%Query{report: "all", filters: [tags: "LATEST"]}, [])

      returning
      |> Enum.map(fn field ->
        type = schema.__schema__(:type, field)

        result
        |> Map.get(Atom.to_string(field))
        |> decode_type(type)
        |> then(&{field, &1})
      end)
      |> then(&{:ok, &1})
    end
  end

  @impl Ecto.Adapter.Schema
  def insert_all(
        _adapter_meta,
        _schema_meta,
        _header,
        _list,
        _on_conflict,
        _returning,
        _placeholders,
        _options
      ) do
    raise "not implemented"
  end

  @impl Ecto.Adapter.Schema
  def update(_adapter_meta, _schema_meta, fields, filters, _returning, _opts) do
    {status, fields} = Keyword.pop(fields, :status)
    fields = Keyword.replace_lazy(fields, :tags, &Enum.join(&1, ","))

    if not Enum.empty?(fields) do
      :ok = Connection.update(filters, fields)
    end

    if status == "completed" do
      :ok = Connection.done(filters)
    end

    {:ok, []}
  end

  @impl Ecto.Adapter.Schema
  def delete(_adapter_meta, _schema_meta, filters, _returning, _opts) do
    :ok = Connection.delete(filters)

    {:ok, []}
  end

  @impl Ecto.Adapter.Schema
  def autogenerate(_field_type) do
    raise "not implemented"
  end
end
