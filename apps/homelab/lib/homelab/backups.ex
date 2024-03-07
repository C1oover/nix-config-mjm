defmodule Homelab.Backups do
  @moduledoc """
  The Backups context.
  """

  require OpenTelemetry.Tracer, as: Tracer

  alias Homelab.Backups.Restic
  alias Homelab.Cache
  alias Homelab.Otel

  def list_archives(locations \\ [:onsite, :offsite]) do
    Tracer.with_span :list_archives do
      {uncached_locations, cached_results} = fetch_cached_results(locations)

      uncached_locations
      |> Enum.map(&async_list_archives(&1))
      |> Task.yield_many(30_000)
      |> Enum.map(fn {task, res} -> res || Task.shutdown(task, :brutal_kill) end)
      |> Enum.flat_map(fn
        {:ok, [first | _rest] = results} -> write_results_to_cache(first.location, results)
        _ -> []
      end)
      |> Kernel.++(cached_results)
      |> Enum.sort(&(DateTime.compare(&1.time, &2.time) != :lt))
    end
  end

  defp async_list_archives(location) do
    Otel.async_nolink(
      fn -> list_archives_by_location(location) end,
      shutdown: :brutal_kill
    )
  end

  def list_archives_by_location(location) do
    Tracer.with_span :list_archives_by_location, %{attributes: %{"backup.location": location}} do
      Restic.list_snapshots(location)
    end
  end

  defp fetch_cached_results(locations) do
    {uncached_locations, results} =
      Enum.reduce(
        locations,
        {[], []},
        fn location, {uncached_locations, acc_results} ->
          case Cache.get({:backups, location}) do
            nil -> {[location | uncached_locations], acc_results}
            results -> {uncached_locations, [results | acc_results]}
          end
        end
      )

    {uncached_locations, List.flatten(results)}
  end

  defp write_results_to_cache(location, results) do
    :ok = Cache.put({:backups, location}, results, ttl: :timer.minutes(10))
    results
  end
end
