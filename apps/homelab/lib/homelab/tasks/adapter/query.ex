defmodule Homelab.Tasks.Adapter.Query do
  defstruct schema: nil, report: nil, filters: []

  def from_ecto(%Ecto.Query{} = query) do
    {report, schema} = query.from.source

    filters = filters_from_wheres(query)

    %__MODULE__{
      schema: schema,
      report: report,
      filters: filters
    }
  end

  defp filters_from_wheres(%Ecto.Query{wheres: wheres}) do
    wheres
    |> Enum.flat_map(&filters_from_where/1)
    |> Enum.reject(&is_nil/1)
  end

  defp filters_from_where(%Ecto.Query.BooleanExpr{op: :and, expr: expr}) do
    filters_from_expr(expr)
  end

  defp filters_from_expr({:and, _, exprs}) do
    Enum.flat_map(exprs, &filters_from_expr/1)
  end

  defp filters_from_expr({:==, _, [left, right]}) do
    field = get_field(left)
    value = get_value(right)

    [{field, value}]
  end

  defp filters_from_expr({:in, _, [left, {{:., _, _}, _, _} = right]}) do
    value = get_value(left)
    field = get_field(right)

    [{field, value}]
  end

  defp filters_from_expr({:in, _, [left, right]}) do
    field = get_field(left)
    values = get_value(right)

    values
    |> Enum.map(&{field, &1})
    |> Enum.intersperse("or")
  end

  defp get_field({{:., _, [{:&, _, [0]}, field]}, _, []}), do: field

  defp get_value({:^, _, [idx]}), do: {:param, idx}

  defp get_value({:^, _, [num_update_terms, num_query_terms]}) do
    num_update_terms..(num_update_terms + num_query_terms - 1)
    |> Enum.map(&{:param, &1})
  end

  defp get_value(value), do: value
end
